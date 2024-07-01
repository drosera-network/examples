// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MockOracle {
    uint256[] internal prices;

    constructor(uint256[] memory _prices) {
        prices = _prices;
    }

    // retrieve the price at the current block number
    function getPrice() external view returns (uint256) {
        uint256 index = block.number;
        return prices[index];
    }
}
