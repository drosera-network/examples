// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ContagionTrap.sol";

contract ContagionTrapTest is Test {
    ContagionTrap trap;

    function setUp() public {
        trap = new ContagionTrap();
    }

    function testTriggerWhenLiquidityDrops() public {
        // Simulate older high liquidity snapshots
        bytes ;
        data[0] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 100, blockNumber: 100 }));
        data[1] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 400, blockNumber: 90 }));
        data[2] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 500, blockNumber: 80 }));

        // Since newest (100) < 50% of avg (450), should trigger
        (bool shouldTrigger, ) = trap.shouldRespond(data);
        assertTrue(shouldTrigger, "Expected trigger when liquidity drops by >50%");
    }

    function testNoTriggerWhenStableLiquidity() public {
        bytes ;
        data[0] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 450, blockNumber: 100 }));
        data[1] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 500, blockNumber: 90 }));
        data[2] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 480, blockNumber: 80 }));

        (bool shouldTrigger, ) = trap.shouldRespond(data);
        assertFalse(shouldTrigger, "Should not trigger when liquidity stable");
    }

    function testInsufficientHistory() public {
        bytes ;
        data[0] = abi.encode(ContagionTrap.PoolSnapshot({ liquidity: 500, blockNumber: 100 }));

        (bool shouldTrigger, bytes memory info) = trap.shouldRespond(data);
        assertFalse(shouldTrigger, "Should not trigger with insufficient history");
        assertEq(string(info), "insufficient_history");
    }
}
