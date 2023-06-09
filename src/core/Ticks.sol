// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

library Ticks {
    struct Tick {
        mapping(uint8 tier => uint256) tierLiquidity;
        int24 nextBelow;
        int24 nextAbove;
    }

    function getLiquidity(Tick storage self, uint8 tier) internal view returns (uint256 liquidity) {
        return self.tierLiquidity[tier];
    }
}
