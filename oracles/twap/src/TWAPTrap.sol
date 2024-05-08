// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockOracle} from "./MockOracle.sol";

/**
 * @title TWAPTrap
 * @dev A trap example that checks for price deviations for a set of timeseries TWAP oracle data.
 * This example shows how a trap can be used to detect price manipulation in a TWAP oracle over a large block range.
 */
contract TWAPTrap {
    uint256 public constant THRESHOLD_MULTIPLIER = 10000;
    uint256 public deviationThreshold = 200; // In basis points (e.g., 500 represents 5%)
    address public mockOracle = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;

    struct PriceDataPoint {
        uint256 price;
    }

    /**
     * @dev Node Operators do not pass in arguments to the constructor and dont expect the contructor to have arguments.
     * The constructor can be used to set values in the contract but the values do not persist across blocks.
     */
    constructor() {}

    /**
     * @dev Collects the latest price data point.
     * @return The latest price data point.
     * @dev This function returns the current price from the MockOracle contract which is sent to `isValid` to check for price deviations.
     */
    function collect() external view returns (PriceDataPoint memory) {
        MockOracle oracleInstance = MockOracle(mockOracle);
        uint256 price = oracleInstance.getPrice();
        return PriceDataPoint({price: price});
    }

    /**
     * @dev Checks if the provided price data points are valid based on the deviation threshold.
     * @param dataPoints An array of price data points to check.
     * @return A boolean indicating whether the price data points are valid.
     */
    function isValid(PriceDataPoint[] calldata dataPoints) external view returns (bool) {
        uint256 dataPointsLength = dataPoints.length;
        if (dataPointsLength < 2) {
            return true;
        }

        uint256 maxPrice = dataPoints[0].price;
        uint256 minPrice = dataPoints[0].price;

        for (uint256 i = 0; i < dataPointsLength; i++) {
            uint256 price = dataPoints[i].price;
            if (price == 0) {
                continue;
            }
            if (price > maxPrice) {
                maxPrice = price;
            } else if (price < minPrice) {
                minPrice = price;
            }
        }

        uint256 priceRange = maxPrice - minPrice;
        uint256 allowedDeviation = (minPrice * deviationThreshold) / THRESHOLD_MULTIPLIER;

        return priceRange <= allowedDeviation;
    }
}
