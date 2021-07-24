//WARNING: Psuedo-code/Draft Phase... Do NOT USE THIS IN PRODUCTION. The current version of this contract is essentially pseudo code containing major functionality that will be edited to be operational by community

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

//Required libs
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//Options Market Liquidity Pool
contract LiquidityPool is  ReentrancyGuard {
    using SafeMath for uint256;

    modifier onlyOwner {
           require(
               msg.sender == owner,
               "Only owner can complete this tx"
           );
           _;
    }
    fallback() external payable { }

    mapping (address=> uint256) public poolOwnerBalance;
    mapping (address=> bool) public tokenAddressWhitelisted;
    address public owner;
    uint256 public poolTotalValue = 0;
    uint256 public poolTotalDeposits = 0;
    address public depositToken = address(0x0);
    address public optionsMarketContract = address(0x0);
    address minimumDepositForAddingAsAuthorized;
    uint256 maxPercentageCapitalForAnyPosition = 2000; // 20%
    uint256 withdrawalDate = 0;
    bool allLPsCanWithdraw = true;


   event CapitalProvided(address optionsMarketAddress, uint256 amount);

    constructor() public payable {
        owner= msg.sender;
    }

    function setDepositToken(address tokenAddress) public onlyOwner{
       address depositToken = tokenAddress;
    }

    function setWithdrawDate(uint256 date) public onlyOwner returns (bool){
        require(date == 0, "Owner cannot change the withdrawal date");
        withdrawalDate = date;
        return true;
    }

    function updateCapitalPercMaxForAnyPosition(uint256 percentage) public onlyOwner returns(bool){
       //1000 = 10%
       maxPercentageCapitalForAnyPosition = percentage;
       return true;
    }

    function deposit(uint256 amount) public payable returns(bool){
       IERC20 dToken = IERC20(depositToken);
       require(dToken.transferFrom(msg.sender, address(this), amount), "You must have the balance of the deposit token and have approved this contract before doing this");
       poolTotalDeposits = poolTotalDeposits.add(amount);
       return true;
    }

    function withdraw() public returns (bool){
        require(allLPsCanWithdraw, "allLPsCanWithdraw must be set to true for LPs to withdraw");
        IERC20 token = IERC20(depositToken);
        uint256 userPercentageOfDeposits = poolOwnerBalance[msg.sender].mul(1000).div(poolTotalDeposits);
        uint256 amountOutputTokensEntitledTo = poolTotalValue.mul(userPercentageOfDeposits);
        token.transfer(msg.sender, userPercentageOfDeposits);
        return true;

    }

    function releaseCapitalAndRewardsForLPClaim() public returns(bool){
        if(block.timestamp>withdrawalDate){
            allLPsCanWithdraw = true;
        }
        return true;
    }

    function whitelistToken(address tokenAddress) public payable onlyOwner returns(bool){
        tokenAddressWhitelisted[tokenAddress] = true;
        return true;
    }

    function provideCapitalForOptionOrder(address tokenAddress, uint256 amountOutputToken) public{
        require(msg.sender == optionsMarketContract, "only the authorized options market can make requests to this contract for liquidity");
        bool authorized= isWhitelistedToken(tokenAddress);
        require(authorized, "This token is not authorized for this pool");

        if(tokenAddress != depositToken){
            uint calculatedInputAmount = swapRate(depositToken, tokenAddress, amountOutputToken);
            uint256 percentageOfTotalDeposits = calculatedInputAmount.mul(1000).div(poolTotalValue);
            require(percentageOfTotalDeposits <= maxPercentageCapitalForAnyPosition, "This amount of liquidity cannot be provided for a single transaction");
            uint256 outputAmount= swapForAmount(depositToken, tokenAddress, amountOutputToken);
        }
        IERC20 token = IERC20(tokenAddress);
        token.transfer(optionsMarketContract, amountOutputToken);
        emit CapitalProvided(optionsMarketContract, amountOutputToken);
    }

    function swapRate(address tokenFromAddress, address tokenToAddress, uint256 amount) view public returns (uint256){
        //gets rate from external AMM or chainlink, then returns
        uint256 swapRate;
        return swapRate;
    }
    function  swapForAmount(address theDepositToken, address tokenAddress, uint256 amountOutputToken) public returns (uint256){
        //Price discovery and swap to needed token occurs here
        return amountOutputToken;
    }

    function isWhitelistedToken(address tokenAddress) public view returns(bool){
       if(tokenAddressWhitelisted[tokenAddress] == true){
           return true;
       }
       else{
           return false;
       }
    }
}
