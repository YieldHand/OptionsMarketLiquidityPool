const LiquidityPool = artifacts.require("LiquidityPool");
const ERC20Mock = artifacts.require("ERC20Mock");

contract('LiquidityPool tests', async ([alice, bob, admin, dev, minter]) => {
    it('create pool and tokens', async () => {
        this.token = await ERC20Mock.new('MOCK', 'MCK', minter, 1000, {from: minter});
        this.pool = await LiquidityPool.new({from: bob});
    });

    it('ensure minter has 1000 tokens', async () => {
        const minterBalance = await this.token.balanceOf(minter);
        assert.equal(minterBalance, 1000, "should have 1000 here")
    });

    it('give 10 tokens to alice', async () => {
        await this.token.mint(alice, 10, {from: minter});
        const balance = await this.token.balanceOf(alice);
        assert.equal(balance, 10, "should have 10 here");
    });

    it('ensure alice can make a deposit of 5 tokens', async () => {
        // Set token as deposit token
        this.pool.setDepositToken(this.token.address, {from: bob});

        // Approve the pool contract to use alice's tokens
        await this.token.approve(this.pool.address, 10, {from: alice});
        const allowance = await this.token.allowance(alice, this.pool.address);
        assert.equal(allowance, 10);

        // Alice make a deposit of 5 token
        await this.pool.deposit(5, {from: alice});

        // assert that balances are ok
        assert.equal(await this.token.balanceOf(this.pool.address), 5);
        assert.equal(await this.token.balanceOf(alice), 5);
        assert.equal(await this.pool.poolOwnerBalance(alice), 5);
        assert.equal(await this.pool.poolTotalDeposits(), 5);
        assert.equal(await this.pool.poolTotalValue(), 5);
    });

    it('ensure alice can withdraw 2 tokens', async () => {
        // Alice withdraw 2 tokens
        await this.pool.withdraw(2, {from: alice});

        // assert that balances are ok
        assert.equal(await this.token.balanceOf(this.pool.address), 3);
        assert.equal(await this.token.balanceOf(alice), 7);
        assert.equal(await this.pool.poolOwnerBalance(alice), 3);
        assert.equal(await this.pool.poolTotalDeposits(), 3);
        assert.equal(await this.pool.poolTotalValue(), 3);
    });
});