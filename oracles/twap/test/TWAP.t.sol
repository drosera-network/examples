// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TWAPTrap} from "../src/TWAPTrap.sol";
import {MockOracle} from "../src/MockOracle.sol";

contract TWAPTrapTest is Test {
    MockOracle oracle;

    function setUp() public {
        // Set up the oracle with a set of prices
        uint256[] memory prices = new uint256[](100);
        for (uint256 i = 0; i < 90; i++) {
            prices[i] = 1 ether;
        }
        for (uint256 i = 90; i < 99; i++) {
            prices[i] = 1.02 ether;
        }
        prices[99] = 1.1 ether;
        oracle = new MockOracle(prices);
    }

    function testTWAPTrap() external {
        TWAPTrap.PriceDataPoint[] memory prices = new TWAPTrap.PriceDataPoint[](100);

        // Simulate blocks and check that the trap is valid with normal prices
        for (uint256 i = 0; i < 90; i++) {
            prices[i] = new TWAPTrap().collect();
            assertTrue(new TWAPTrap().isValid(prices), "Trap should be valid with normal prices");
            // Simulate a block
            vm.roll(block.number + 1);
        }
        console2.log(block.number);

        // Simulate price manipulation over multiple blocks
        for (uint256 i = 90; i < 99; i++) {
            prices[i] = new TWAPTrap().collect();
            assertTrue(new TWAPTrap().isValid(prices), "Trap should remain valid during initial manipulation");
            // Simulate a block
            vm.roll(block.number + 1);
        }
        console2.log(block.number);

        // Simulate a larger price deviation
        prices[99] = new TWAPTrap().collect();

        // Check that the trap is triggered with the larger price deviation
        assertTrue(!new TWAPTrap().isValid(prices), "Trap should be triggered with larger price deviation");
    }
}
