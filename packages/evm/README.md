# Dry Powder [![GitHub Actions][gha-badge]][gha]

[gha]: https://github.com/numoen/dry-powder/actions
[gha-badge]: https://github.com/numoen/dry-powder/actions/workflows/main.yml/badge.svg

A non-custodial, exchange protocol for efficiently trading options on the Ethereum Virtual Machine (EVM). 

By enabling the borrowing of liquidity shares from a concentrated liquidity AMM, users can mint fully on-chain, perpetual options on any asset without oracles and minimized liquidation risk. This allows traders to fully express any financial payoff with minimal trust assumptions for the first time on a blockchain.

Features:

- Aggregate of constant-sum liquidity pools with spaced strike prices
- Reserve the right to swap on liquidity with built in, overcollateralized, liquidation-free lending
- Custom fee settings within each pair with inherent, optimal, on-chain routing between them
- Single contract architecture

## Benchmarking

|                   |Dry Powder|Uniswap V3|LiquidityBook|Maverick|
|-------------------|----------|----------|-------------|--------|
|Loc                |          |          |             |        |
|Create new pair    |          |          |             |        |
|Add Liqudity       |          |          |             |        |
|Small Swap         |          |          |             |        |
|Large Swap         |          |          |             |        |
|Borrow Liquidity   |          |          |             |        |

## Concepts

### Automated Market Maker

Dry Powder is an automated market maker (AMM) that allows for exchange between two assets by managing a pool of reserves referred to as a liquidity pool. Automated market makers are guided by an invariant, which determines whether a trade should be accepted.

Dry Powder is uses the invariant `Liquidity = Price * amount0 + amount1`, also referred to as **constant sum**, with price having units `Price: token1 / token0`.

Simply put, automated market makers create a market between two classes of users. Traders want to swap token0 to token1 or vice versa, presumably because they believe it will benefit them in someway. Liquidity providers lend out a combination of token0 and token1, that is used to facilitate traders. They are rewarded for this with a portion of all traders trades. This market aims to connect traders and liquidity providers in a way that leaves them both satisfied with the opportunity.

### Creating Option Token

First implemented in Numoen's Power Market Maker Protocol (pmmp) is the ability to **reserve the rights to swap** by borrowing liquidity. Thereby making swaps and borrowing empirically the same. To do this, users post collateral that they know will always be more valuable than the value of the liquidity they want to borrow. With this collateral, a user would borrow liquidity and immediately withdraw into the underlying tokens in hopes that they can repay the liquidiity for a cheaper price in the future.

For example, let's assume the price of ether is currently $1000. Alice borrows 1 unit of liquidity at a strike price of $1500 that contains 1 ether or 1500 usdc, but because the market price is below the strike price, it is redeemable for 1 ether currently. As collateral, alice uses the 1 ether that was redeemed plus .1 ether of her own. The market price then moves to $2000 per ether. Alice sells the 1.1 ether for 2200 usdc, uses 1500 of the usdc to mint a liquidity token and payback her debt, profiting 700 usdc from a 100% price move with $100 of principal.

Obviously, users must pay for the ability to acheive asymmetric exposure. In this protocol, positions that are borrowing active liquidity are slowly liquidated by having their collateral seized and being forgiven of their debt. We call this a continous liquidation and is keeperless. Interest is accrued per block and, explained in more detail in the next section, borrow rates are proportional to swap fees which are related to volatility and block times.

This has drastic impacts on the low level economics of AMMs. The profitablity of popular exchange protocols is debated because liquidity providers suffer from a phenomenom known as Loss Versus Rebalancing (LVR pronounced lever). This is essentially a cost to liquidity providers that comes from external arbitrageurs having more informed market information than the protocol. These protocols are able to remain profitable by uninformed retail traders using them as a means of exchange, but this approach isn't sustainable. Two undesireable outcomes are the fact that:

1. Arbitrageurs never lose money, they simply won't take any action if the trade is unprofitable.
2. When arbitrageurs are bidding against eachother, their payment goes to validators instead of liquidity providers.

Reserving the rights to swap or borrowing liquidty solves these problems. Actors who were previously profiting on the volatility of assets by arbitraging are now able to borrow liquidity and repay it when the market price moves. These actors now are unprofitable when the cost of borrowing is more than the arbitrage profit. We do not attempt to "solve" LVR, but instead make sure it is appropriately priced by allowing the other side of the trade or "gain versus rebalancing". In short, this protocol provides an avenue for users to borrow liquidity when it has been over provided.

### Options Pricing

Each liquidity position both convex and concave is analagous to a replicated options portfolio whose payoff can perfectly match that of any option. With no expiry, the pricing is both simpler and perpetual.

For pricing these derivatives, we relate the cost to the implied volatility of the underlying assets and the block frequency. We make some assumptions about arbitageur behavior: there is only one trade per block, that takes the AMM from a stale price to the current price.

We first take a look at arbitrageur profit. Without fees arbitrageur profit is $ArbitrageurProfit = a * (p - q)$, with

- a: Amount traded
- p: Market price
- q: AMM price

We define $\Delta\ P= p - q$ and can simplify the above equation to $ArbitrageurProfit = a * \Delta\ P$. We can further simplify a to be the amount of liquidity $l$, giving $ArbitrageurProfit = l * \Delta\ P$.

The swap fee shifts the AMM price by $f$, therefore shrinking arbitrageur profit. Now $ArbitrageurProfit =  a * (p - (1+f)q)$. If we set this to zero and solve for $f$, we get $f = \frac{\Delta\ P}{q}$.


### Strikes (Aggregate Liquidity)

In order to allow for maximum simplicity and expressiveness, Dry Powder is an aggregate of up to 2^24 or 16,777,216 constant sum automated market makers. Each individual market is designated by its **strike** which is directly mapped to a price according to the formula `Price = (1.0001)^strike`, such that each strike is 1 bip away from adjacent strikes. This design is very similar to Uniswap's concentrated liquidity except that liquidity is assigned directly to a fixed price, because of the constant sum invariant. Dry Powder manages swap routing so that all trades swap through the best available price.

### Spreads

Dry Powder allows liquidity providers to impose a fee on their liquidity when used for a trade. Many popular AMM designs measure fees based on a fixed percentage of the input of every trade. Dry Powder takes a different approach and instead fees are described as a spread on the underlying liquidity. For example, liquidity placed at strike 10 with a spread of 1 is willing to swap 0 -> 1 (sell) at strike 11 and swap 1 -> 0 (buy) at strike 9.

This design essentially allows for fees to be encoded in strikes for more efficient storage and optimal on-chain routing. Dry Powder has multiple spread tiers per pair.

It is important to note that with a larger spread, pricing is less exact. For example, a liquidity position that is willing to trade token0 to token1 at strike -10 and trade token 1 to token0 at strike -3 will not be used while the global market price is anywhere between strike -10 and -3. Liquidity providers must find the correct balance for them of high fees and high volume.

### Limit orders

Dry Powder allows liquidity providers to only allow for their liquidity to be used in one direction, equivalent to a limit order. This is done without any keepers or third parties, instead natively available on any pair. The limit orders implemented in Dry Powder are of the "partial fill" type, meaning they may not be fully swapped at once.

## Architecture

### Engine (`core/Engine.sol`)

Dry Powder uses an engine contract that manages the creation and interaction with each pair. Contrary to many other exchanges, pairs are not seperate contracts but instead implemented as a library. Therefore, the engine smart contract holds the state of all pairs. This greatly decreases the cost of creating a new pair and also allows for more efficient multi-hop swaps.

In the `Engine.sol` contract, information about different token pairs are stored and retrieved in the internal mapping called `pairs`, which maps a pair identifier computed using token addresses to a `Pairs.Pair` struct. This struct contains data related to a specific token pair, such as where liquidity is provided and what spread is imposed on that liquidity.

The Engine accepts an array of commands and an equal length array of inputs. Each command is an action that can be taken on a specific pair, such as `createPair()`, `addLiquidity()`, `removeLiquidity()`, or `swap()`. Each input is a bytes array that can be decoded into the inputs to each command. In a loop, commands are executed on the specified pair, and the effects are stored for later use.

After all commands have been executed, the gross outputs are transferred to the specified recipient. A callback is called, and after the gross inputs are expected to be received. This architecture allows for every command to use flash accounting, where outputs are transferred out first then arbitrary actions can be run before expecting the inputs.

### Pair (`core/Pairs.sol`)

Each individual market, described by `token0` and `token1` is an instance of a pair. Pairs contains all accounting logic.

Pairs have several state variables including:

- `composition`, and `strikeCurrent`: Information for each spread. Composition represents the portion of the liquidity that is held in `token1`. The current strike is the last strike that was used for a swap for that specific spread.
- `cachedStrikeCurrent`: The last strike that was traded through for the entire pair. This save computation and can lead to less storage writes elsewhere.
- `cachedBlock`: The last block that interest was accumulated at the current strike.
- `strikes`: Information for each strike. BiDirectional liquidity is the type of liquidity that is conventially stored in an AMM. Each index of the array represents a spread tier. Borrowed liquidity is the amount of liquidity borrowed per spread. Total supply is a unit that represents a share of liquidity per spread, and is useful when calculating how much fees have been generated. Dry Powder also implements limit orders, or directional orders that are automatically closed out after being used to facilitate a trade. Limit orders need to store liquidity information as well as variables that can be used to determine if a specific limit order is closed. Strikes also contains two, singley-linked lists. These lists relate adjacent strikes together. This is needed because looping to find the next active adjacent strike is infeasible with 2**24 possible strikes.

Pairs also contain two functions to manage the state variables:

- `swap()`: Swap from one token to another, routing through the best priced liquidity.
- `updateStrike()`: Either add or remove liquidity from a strike.
- `borrowLiquidity()`: Borrow liquidity from a certain strike.
- `repayLiquidity()`: Repay liquidity to a certain strike.
- `accrue()`: Accrue interest to the current strike, forgiving borrowers of a certain amount and reposessing their collateral.

### BitMaps (`core/BitMaps.sol`)

BitMaps is a library used in `Pairs.sol`. Its purpose is to manage and store information about initialized strikes. Implemented in the library is a three level bitmap which is a data structure used for storing binary data about an array in a compact way. Simply, a `1` bit represents an initialized strike, and storing the data this way allows for efficient computation of the next initialized strike below any arbitrary value.

### Positions (`core/Positions.sol`)

Positions stores users liquidity positions in Dry Powder. Positions implements a standard called `ILRTA`, which supports transferability with and without signatures. There are three types of positions, BiDirectional, Limit, Debt. BiDirectional is the standard AMM liquidity, with the amount representing the share of the underlying liquidity, similar to Uniswap V2. A limit order has units of strictly liquidity (limit orders can't have fees) and contains extra information (`liquidityGrowthLast`) that is vital for telling if a limit order has been fully closed or not. Debt positions represent borrowed liquidity + collateral. Debt positions are denominated in liquidity without any interest accrued and contain extra data point `leverageRatioX128` that is equal to a multiple of how much collateral to debt in units of liquidity without any interest accrued.

### Router (`periphery/Router.sol`)

A router is used to interact with the Engine. Router uses a signature based token transfer scheme, `Permit3`, to pay for the inputs for command sent to the Engine. Liquidity positions can also be transferred by signature. This makes the router hold no state, including approvals. Router can therefore be seamlessly replaced at no cost to users.

## Development

## Acknowledgements
