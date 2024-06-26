// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ForkTrap} from "../src/traps/ForkTrap.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// @dev forge test --match-contract ForkTrapTest -vvvv
contract ForkTrapTest is Test {
    uint256 preExploitFork;
    uint256 exploitFork;

    function setUp() public {
        preExploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 14506358);
        exploitFork = vm.createSelectFork(vm.rpcUrl("mainnet"), 20006036);
    }

    function test_ForkTrap() external {
        ForkTrap.CustomCollectStruct[]
            memory data = new ForkTrap.CustomCollectStruct[](2);

        vm.selectFork(preExploitFork);
        data[1] = new ForkTrap().collect();

        vm.selectFork(exploitFork);
        data[0] = new ForkTrap().collect();

        bool isValid = new ForkTrap().isValid(data);
        assert(isValid == false);
    }
}
