// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EulerTrap} from "../src/EulerTrap.sol";

contract EulerTrapTest is Test {
    uint256 preExploitFork;
    uint256 exploitFork;

    function setUp() public {
        preExploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 16_817_995);
        exploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 16_817_996); // hacked block
    }

    function test_FindExploit() public {
        bytes[] memory data = new bytes[](2);
        vm.selectFork(preExploitFork);

        data[1] = new EulerTrap().collect();

        vm.selectFork(exploitFork);
        data[0] = new EulerTrap().collect();

        (bool shouldRespond, bytes memory response) = new EulerTrap().shouldRespond(data);
        assertEq(shouldRespond, true);
    }
}
