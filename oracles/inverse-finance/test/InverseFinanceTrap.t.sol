// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InverseFinanceTrap} from "../src/InverseFinanceTrap.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract InverseFinanceTrapTest is Test {
    uint256 preExploitFork;
    uint256 exploitFork;

    function setUp() public {
        preExploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 14506358);
        exploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 14506359);
    }

    function test_twapTrap() external {
        bytes[]
            memory prices = new bytes[](2);
        vm.selectFork(preExploitFork);
        prices[1] = new InverseFinanceTrap().collect();

        vm.selectFork(exploitFork);
        prices[0] = new InverseFinanceTrap().collect();
        (bool shouldRespond, ) = new InverseFinanceTrap().shouldRespond(prices);
        assertTrue(shouldRespond);
    }
}
