# OptionsMarketLiquidityPool

A liquidity pool that provides dynamic underlying assets for option contract market orders on-demand and distributes premiums to pool members

## Problem

One of the biggest issues in DeFi-based options markets is the lack of liquidity for any given strike price and desired expiry date. Options are not commonly traded because buyers are not able to find sellers and vice versa. Previously, to solve this problem in the direct swaps market, Uniswap employed automated market makers (AMMs) which could fill the orderbook gaps for desired orders. However, this type of dynamic making of markets is non-existent in DeFi-based options markets.


## Solution

To solve this liquidity issue in options markets, we are taking a similar approach that Uniswap took with the automated market maker model. Liquidity is added to pools which whitelist various tokens (underlying) and provide liquidity on-demand from attached options market smart contract requests to fill option purchase market orders. These options markets have their own direct liquidity for specific strike prices and expiration dates; however, when there is not enough liquidity to fill an order, a call is made to this projects' liquidity pools which provide the opposite side of the trade for an enhanced premium, giving the options buyer exposure to their desired option terms while collecting premiums as rewards for providing the whitelisted underlying tokens for the trade to the liquidity providers of the option liquidity pools.



## Core Features

The primary contract with core functionality can be found in `contracts/pool.sol`

The primary functions are:

-`deposit`: Deposit tokens by any user (stablecoins typically though all pools can be different)

-`withdraw`: Withdraw rewards and percentage of the pool after the expiration of the pool (likely to be 3 month to one year from deposit)

-`releaseCapitalAndRewardsForLPClaim`: Anyone can call this function which can be triggered after the withdraw date has been met and all possible options have expired.

-`swapForAmount`: Leverages AMMs (such as Uniswap) to convert the deposit token (stablecoin) to the desired underlying token to accommodate and options purchase order made on the whitelisted options market contract.

-`provideCapitalForOptionOrder`: This function is called by the options contract, and if the criteria is met, this contract then provides the desired liquidity on the other side to fill an option purchasers order.


## Why It's Different From Alternatives

Alternative pools that attempt to accomplish similar results typically have one pool for each type of underlying. There are pools that specific to USDC-DAI pairs, ETH-DAI pair etc, versus the ability (as here) to provide a stablecoin for a variety of pairs in a similar category and take advantage of a variety of premiums over a given liquidity pool-determined period of time.

Further, current liquidity pools do not take advantage of diversification and DAO-based decisions on yield goals that can result in enhanced results for liquidity providers.


## What's Next?

 We are currently working to add comprehensive tests to this project. Additionally, we are working to add tokenization of the LP Pools so that LP positions can be traded on platforms such as Pendle and APWine for fixed yield.


## Contribute

We welcome you to contribute to this codebase by forking this project and submitting pull requests to the `develop` branch. For any questions, comments, or suggestions, we encourage you to reach us in our Discord: https://discord.gg/7fApFnA6qW

### Development And test environment

- use nvm to manage the npm version. If you don't want to use nvm, the supported npm version is in .nvmrc file.
- package.json defines libraries versions used by the project

#### Available commands

- build

```npm run build```

- compile

```npm run compile```

- migrate

```npm run migrate```

- test

```npm run test```
