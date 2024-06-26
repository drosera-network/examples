// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IKeep3rV2Oracle {
    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo);
}

contract InverseFinanceTrap {
    struct PriceDataPoint {
        uint256 price;
        uint256 timestamp;
    }

    IKeep3rV2Oracle oracle =
        IKeep3rV2Oracle(0x39b1dF026010b5aEA781f90542EE19E900F2Db15); // Address of the Sushi INV/WETH Keep3rV2Oracle
    IERC20 inv = IERC20(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68); // Address of the INV token
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Address of the WETH token

    uint256 public constant PRICE_DEVIATION_THRESHOLD = 10; // 10% deviation threshold

    function collect() external view returns (PriceDataPoint memory) {
        (uint256 amountOut, uint256 lastUpdatedAgo) = oracle.current(
            address(inv),
            1 ether,
            address(weth)
        );

        return PriceDataPoint({price: amountOut, timestamp: lastUpdatedAgo});
    }

    function isValid(
        PriceDataPoint[] calldata dataPoints
    ) external pure returns (bool) {
        uint256 len = dataPoints.length;
        if (len < 2) {
            return true;
        }

        for (uint256 i = 1; i < len; i++) {
            PriceDataPoint memory currentPrice = dataPoints[i - 1];
            PriceDataPoint memory prevPrice = dataPoints[i];

            uint256 priceDiff = (currentPrice.price > prevPrice.price)
                ? currentPrice.price - prevPrice.price
                : prevPrice.price - currentPrice.price;

            uint256 priceDeviation = (priceDiff * 100) / prevPrice.price;

            if (priceDeviation > PRICE_DEVIATION_THRESHOLD) {
                return false;
            }
        }

        return true;
    }
}
