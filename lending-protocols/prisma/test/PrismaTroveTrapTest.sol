// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PrismaTroveTrap} from "../src/PrismaTroveTrap.sol";

contract PrismaTroveTrapTest is Test {
    uint256 preExploitFork;
    uint256 exploitFork;

    function setUp() public {
        preExploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 19532296);
        exploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 19532297);
    }

    function test_prismaTroveTrap() public {
        bytes[]
            memory dataPoints = new bytes[](2);

        // Select the pre-exploit fork
        vm.selectFork(preExploitFork);

        // Collect the data points before the exploit occurred
        dataPoints[1] = new PrismaTroveTrap().collect();

        // Select the exploit fork
        vm.selectFork(exploitFork);

        // Collect the data points after the exploit occurred
        dataPoints[0] = new PrismaTroveTrap().collect();

        // Check if the exploit succeeded in draining the user's collateral
        (bool shouldRespond, ) = new PrismaTroveTrap().shouldRespond(dataPoints);

        // Assert the shouldRespond function returns true triggering the emergency response
        assertTrue(shouldRespond);
    }
}
