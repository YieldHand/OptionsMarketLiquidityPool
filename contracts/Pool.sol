// SPDX-License-Identifier: MIT
//WARNING: Psuedo-code/Draft Phase... Do NOT USE THIS IN PRODUCTION. The current version of this contract is essentially pseudo code containing major functionality that will be edited to be operational by community
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;
//Required libs
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//Options Market Liquidity Pool
contract LiquidityPool is ReentrancyGuard {
    using SafeMath for uint256;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can complete this tx");
        _;
    }

    //allow deposits of ETH
    fallback() external payable {}

    receive() external payable {}

    //mapping of each user's balance in the pool, similar to ERC20 balanceOf
    mapping(address => uint256) public poolOwnerBalance;
    //All tokens that this pool will accept to provide options liquidity for
    mapping(address => bool) public tokenAddressWhitelisted;
    //owner of the contract is ideally a DAO that can make decisions about when to initiate the pool and important rules it will follow
    address public owner;
    //Current total value... Most useful when withdrawals are happening versus its brother below which is how much was ever deposited
    uint256 public poolTotalValue = 0;
    //factor for percentage scaling
    uint256 public percScale = 1e18;
    //Total amount ever deposited here
    uint256 public poolTotalDeposits = 0;
    //The token (usually a stablecoin such as DAI that is accepted as a deposit to contribute to a user's poolOwnerBalance)
    // address public depositToken = address(0x0);
    IERC20 private _depositToken;

    //The options market contract that is allowed to request the liquidity of this pool to it if it follows the rule fo the pool
    address public optionsMarketContract = address(0x0);
    //The maximum percentage that can be contributed by the pool for any given position or liquidity request
    uint256 maxPercentageCapitalForAnyPosition = 2000; // 20%
    //The date set by owner DAO whereby liquity can be withdrawn... No options can expire after this date
    uint256 withdrawalDate = 0;
    //Variable (boolean) that determines whether LPS can withdraw... is triggered to flase when pool officially starts, and set back to true when the pool ends... Users can at any point... if they are LP... withdraw thier rewards from this contract
    bool allLPsCanWithdraw = true;
    //Event triggered for Graph and users on Etherscan/ other explorers to track
    event CapitalProvided(address optionsMarketAddress, uint256 amount);

    //LP Pool Deposit token events
    event Transfer(address from, address to, uint256 tokens);
    event Approval(address approver, address spender, uint256 amount);

    //Set creator as owner initially
    constructor() payable {
        owner = msg.sender;
    }

    //Token that can be received as a deposit by LPs
    function setDepositToken(IERC20 token) public onlyOwner {
        _depositToken = token;
    }

    //date by which deposits can be withdrawn with rewards
    function setWithdrawDate(uint256 date) public onlyOwner returns (bool) {
        require(date == 0, "Owner cannot change the withdrawal date");
        withdrawalDate = date;
        return true;
    }

    //the owner (DAO) can set the maximum percentage of total that can be used ina given requested position
    function updateCapitalPercMaxForAnyPosition(uint256 percentage)
        public
        onlyOwner
        returns (bool)
    {
        //1000 = 10%
        maxPercentageCapitalForAnyPosition = percentage;
        return true;
    }

    //User deposits and becomes an LP
    function deposit(uint256 amount) public payable returns (bool) {
        require(
            _depositToken.transferFrom(msg.sender, address(this), amount),
            "You must have the balance of the deposit token and have approved this contract before doing this"
        );
        poolTotalDeposits = poolTotalDeposits.add(amount);
        poolTotalValue = poolTotalValue.add(amount);
        poolOwnerBalance[msg.sender] = poolOwnerBalance[msg.sender].add(amount);
        return true;
    }

    function calculatePercentage(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return ((_amount.mul(percScale)).mul(100).div(poolTotalDeposits));
    }

    //User withdraws their tokens after the expiration date of the pool
    function withdraw(uint256 amount) public returns (bool) {
        require(
            allLPsCanWithdraw,
            "allLPsCanWithdraw must be set to true for LPs to withdraw"
        );
        uint256 userPercentageOfDepositsAsPercScale = calculatePercentage(
            amount
        );
        uint256 amountOutputTokensEntitledTo = (
            poolTotalValue.mul(userPercentageOfDepositsAsPercScale)
        ).div(percScale).div(100);
        poolOwnerBalance[msg.sender] = poolOwnerBalance[msg.sender].sub(amount);
        poolTotalDeposits = poolTotalDeposits.sub(amount);
        poolTotalValue = poolTotalValue.sub(amountOutputTokensEntitledTo);
        _depositToken.transfer(msg.sender, amountOutputTokensEntitledTo);
        return true;
    }

    //User withdraws their percentage of the pool and rewards
    function withdrawAll() public returns (bool) {
        //User total Balance of the pool after the expiration of the pool
        return true;
    }

    //Called by any user after the withdrawal/expiration date of the pool to trigger the ability for LPs to withdraw their rewards+initial send
    function releaseCapitalAndRewardsForLPClaim() public returns (bool) {
        if (block.timestamp > withdrawalDate) {
            allLPsCanWithdraw = true;
        }
        return true;
    }

    //Owner (DAO) can set which tokens it will enter markets of
    function whitelistToken(address tokenAddress)
        public
        payable
        onlyOwner
        returns (bool)
    {
        tokenAddressWhitelisted[tokenAddress] = true;
        return true;
    }

    //OptionsMarket calls this function to get capital to create sell orders for someones options purchase order, setting the premium based on rules of the pool
    function provideCapitalForOptionOrder(
        IERC20 token,
        uint256 amountOutputToken
    ) public {
        require(
            msg.sender == optionsMarketContract,
            "only the authorized options market can make requests to this contract for liquidity"
        );
        bool authorized = isWhitelistedToken(token);
        require(authorized, "This token is not authorized for this pool");

        if (token != _depositToken) {
            uint256 calculatedInputAmount = swapRate(
                _depositToken,
                token,
                amountOutputToken
            );
            uint256 percentageOfTotalDeposits = calculatedInputAmount
                .mul(1000)
                .div(poolTotalValue);
            require(
                percentageOfTotalDeposits <= maxPercentageCapitalForAnyPosition,
                "This amount of liquidity cannot be provided for a single transaction"
            );
            // uint256 outputAmount = swapForAmount(_depositToken, token, amountOutputToken);
        }
        token.transfer(optionsMarketContract, amountOutputToken);
        emit CapitalProvided(optionsMarketContract, amountOutputToken);
    }

    //Gets the chainlink and/or uniswap rate for a token (Should not be suseptible to flash attacks, therefore best from a trusted oracle)
    function swapRate(
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amount
    ) public pure returns (uint256) {
        //gets rate from external AMM or chainlink, then returns
        uint256 swapRate;
        return swapRate;
    }

    function updateOwnerDAO(address newDAO) public onlyOwner returns (bool) {
        owner = newDAO;
        return true;
    }

    //Swaps a token using the best route... ETH->DAI or ETH->USDC->DAI to get the best reate for the user.
    function swapForAmount(
        IERC20 theDepositToken,
        IERC20 token,
        uint256 amountOutputToken
    ) public pure returns (uint256) {
        //Price discovery and swap to needed token occurs here
        return amountOutputToken;
    }

    //informs the contract or a user quering whether a token can be leveraged to facilitate a sell order of an option to accomodate a buy  being made in the market
    function isWhitelistedToken(IERC20 token) public view returns (bool) {
        if (tokenAddressWhitelisted[address(token)] == true) {
            return true;
        } else {
            return false;
        }
    }

    //dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) public returns (bool) {
        _depositToken.approve(spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev transsfer Moves `amount` tokens from the caller's account to `recipient`.
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(poolOwnerBalance[msg.sender] >= amount, "Insufficient funds");
        require(recipient != address(0), "This address does not exist");
        _depositToken.transferFrom(msg.sender, recipient, amount);
        poolOwnerBalance[msg.sender] = poolOwnerBalance[msg.sender].add(amount);
        poolOwnerBalance[recipient] = poolOwnerBalance[recipient].sub(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev transferfrom Moves `amount` tokens from `sender` to `recipient`,
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(poolOwnerBalance[sender] >= amount, "Insufficient funds");
        require(recipient != address(0), "This address does not exist");
        _depositToken.transferFrom(sender, recipient, amount);
        poolOwnerBalance[sender] = poolOwnerBalance[sender].add(amount);
        poolOwnerBalance[recipient] = poolOwnerBalance[recipient].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
