// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ITrap} from "../interfaces/ITrap.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (
        uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast
    );
}

/**
 * @title ContagionTrap
 * @notice Monitors a neighbor DEX pool; triggers if newest liquidity < 50% of
 *         the average of previous snapshots in the window.
 */
contract ContagionTrap is ITrap {
    address public constant NEIGHBOR_DEX_POOL = 0x0000000000000000000000000000000000000000;

    struct PoolSnapshot {
        uint256 liquidity;
        uint256 blockNumber;
    }

    function collect() external view override returns (bytes memory) {
        (uint112 r0, uint112 r1, ) = IUniswapV2Pair(NEIGHBOR_DEX_POOL).getReserves();
        uint256 liq = uint256(r0) + uint256(r1);
        return abi.encode(PoolSnapshot({ liquidity: liq, blockNumber: block.number }));
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool shouldTrigger, bytes memory responseData)
    {
        if (data.length < 2) return (false, bytes("insufficient_history"));

        PoolSnapshot memory newest = abi.decode(data[0], (PoolSnapshot));

        uint256 sum;
        for (uint256 i = 1; i < data.length; i++) {
            PoolSnapshot memory s = abi.decode(data[i], (PoolSnapshot));
            sum += s.liquidity;
        }

        uint256 avgPrev = sum / (data.length - 1);
        if (newest.liquidity * 2 < avgPrev) {
            return (true, bytes(""));
        }

        return (false, bytes(""));
    }
}
