const LiquidityPool = artifacts.require("LiquidityPool");
const ERC20Mock = artifacts.require("ERC20Mock");

contract('LiquidityPool tests', async ([alice, bob, admin, dev, minter]) => {
    it('create pool and token', async () => {
        this.token = await ERC20Mock.new('MOCK', 'MCK', minter, 1000, {from: minter});
        this.pool = await LiquidityPool.new({from: bob});
    });

    it('ensure minter has 1000 token', async () => {
        const minterBalance = await this.token.balanceOf(minter);
        assert.equal(minterBalance, 1000, "should have 1000 here")
    });

    it('give 10 token to alice', async () => {
        await this.token.mint(alice, 10, {from: minter});
        const balance = await this.token.balanceOf(alice);
        assert.equal(balance, 10, "should have 10 here");
    });

    it('should instanciate pool with a token', async () => {
        // Set token as deposit token
        this.pool.setDepositToken(this.token.address, {from: bob});

        // Approve the pool contract to use alice's tokens
        await this.token.approve(this.pool.address, 10, {from: alice});
        const allowance = await this.token.allowance(alice, this.pool.address);
        assert.equal(allowance, 10, "should have 10 here");

        // Alice make a deposit of 5 token
        await this.pool.deposit(5, {from: alice});

        // assert that balance are ok
        const poolBalance = await this.token.balanceOf(this.pool.address);
        const aliceBalance = await this.token.balanceOf(alice);
        assert.equal(poolBalance, 5, "should have 5 here");
        assert.equal(aliceBalance, 5, "should have 5 here");
    });
});