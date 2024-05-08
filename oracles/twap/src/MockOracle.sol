// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MockOracle {
    uint256[] internal prices;

    constructor(uint256[] memory _prices) {
        prices = _prices;
    }

    // retrieve the price at the current block number
    function getPrice() external view returns (uint256) {
        uint256 index = 0;
        if (block.number > prices.length) {
            index = prices.length - 1;
        } else {
            index = block.number - 1;
        }
        return prices[index];
    }
}
