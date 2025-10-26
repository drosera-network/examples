// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ITrap.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );
}

/**
 * ContagionTrap
 * - data[0] is newest snapshot (Drosera convention)
 * - shouldRespond returns (true, "") when we want to call pause()
 *
 * - compute naive liquidity = reserve0 + reserve1
 * - compute average of previous snapshots (exclude newest index 0)
 * - require avgPrev > MIN_LIQUIDITY_FLOOR to avoid tiny pools
 * - trigger when newest < THRESHOLD * avgPrev (threshold = 0.5)
 */
contract ContagionTrap is ITrap {
    address public immutable NEIGHBOR_DEX_POOL;
    address public immutable LENDING_PROTOCOL;

    struct PoolSnapshot {
        uint256 liquidity;
        uint256 blockNumber;
    }

    uint256 public constant THRESH_NUM = 1;   // (THRESH_NUM / THRESH_DEN) = 0.5
    uint256 public constant THRESH_DEN = 2;
    uint256 public constant MIN_LIQUIDITY_FLOOR = 1_000_000; // adjust if your pool units differ

    constructor(address _neighborDex, address _lendingProtocol) {
        NEIGHBOR_DEX_POOL = _neighborDex;
        LENDING_PROTOCOL = _lendingProtocol;
    }

    /// collect: called by operators to snapshot neighbor pool
    function collect() external view override returns (bytes memory) {
        (uint112 r0, uint112 r1, ) = IUniswapV2Pair(NEIGHBOR_DEX_POOL).getReserves();
        uint256 liq = uint256(r0) + uint256(r1);
        return abi.encode(PoolSnapshot({ liquidity: liq, blockNumber: block.number }));
    }

    /// shouldRespond: Drosera passes an array of snapshots (data[0] newest)
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool shouldTrigger, bytes memory responseData)
    {
        // Need at least newest + one previous snapshot
        if (data.length < 2) return (false, bytes("insufficient_history"));

        PoolSnapshot memory newest = abi.decode(data[0], (PoolSnapshot));

        // compute average of previous snapshots (indices 1..data.length-1)
        uint256 sum = 0;
        uint256 count = 0;
        for (uint256 i = 1; i < data.length; ++i) {
            PoolSnapshot memory s = abi.decode(data[i], (PoolSnapshot));
            sum += s.liquidity;
            unchecked { ++count; }
        }
        if (count == 0) return (false, bytes("no_baseline"));

        uint256 avgPrev = sum / count;

        // Avoid triggering on tiny pools or tiny baselines
        if (avgPrev < MIN_LIQUIDITY_FLOOR) return (false, bytes("baseline_too_small"));

        // Trigger if newest < THRESH * avgPrev  (THRESH = 0.5 here)
        // Cross multiply to avoid precision issues
        if (newest.liquidity * THRESH_DEN < avgPrev * THRESH_NUM) {
            // pause() has no args — return empty bytes
            return (true, bytes(""));
        }

        return (false, bytes(""));
    }
}
