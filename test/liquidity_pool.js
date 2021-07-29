const LiquidityPool = artifacts.require("LiquidityPool");
const ERC20Mock = artifacts.require("ERC20Mock");

contract('LiquidityPool tests', ([alice, bob, admin, dev, minter]) => {
    it('should instanciate pool with a token', async () => {
        const mockToken = await ERC20Mock.new('MOCK', 'MCK', minter, 1000, {from: minter});
        const pool = await LiquidityPool.new({from: bob});
        const minterBalance = await mockToken.balanceOf(minter);
        assert.equal(minterBalance, 1000, "should have 1000 here")
        await mockToken.mint(alice, 10, {from: minter});
        const balance = await mockToken.balanceOf(alice);
        assert.equal(balance, 10, "should have 10 here");
        pool.setDepositToken(mockToken.address, {from: bob});


        await mockToken.approve(pool.address, 10, {from: alice});
        // await mockToken.increaseAllowance(pool.address, 10, {from: alice});
        const allowance = await mockToken.allowance(alice, pool.address);
        assert.equal(allowance, 10, "should have 10 here");

        // await debug(mockToken.transferFrom(alice, pool.address, 5, {from: alice}));
        await pool.deposit(5, {from: alice});

        const poolBalance = await mockToken.balanceOf(pool.address);
        const aliceBalance = await mockToken.balanceOf(alice);
        assert.equal(poolBalance, 5, "should have 5 here");
        assert.equal(aliceBalance, 5, "should have 5 here");
    });
});