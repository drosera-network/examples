// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AVSSlashingTrap.sol";

contract AVSSlashingTrapTest is Test {
    AVSSlashingTrap public trap;

    address validator1 = address(0x1);
    address validator2 = address(0x2);

    function setUp() public {
        trap = new AVSSlashingTrap();
    }

    function testInitialValidatorState() public view {
        assertEq(trap.validatorSignatures(validator1), 0);
        assertEq(trap.lastActiveBlock(validator1), 0);
    }

    function testUpdateValidatorData() public {
        trap.updateValidatorData(validator1, 1);
        assertEq(trap.validatorSignatures(validator1), 1);
        assertEq(trap.lastActiveBlock(validator1), block.number);
    }

    function testValidValidator() public {
        trap.updateValidatorData(validator1, 1);
        bool isValid = trap.isValid(validator1);
        assertTrue(isValid, "Validator should be valid");
    }

    function testSlashingDetection() public {
        trap.updateValidatorData(validator1, 2); // Exceeding max signatures
        bool isValid = trap.isValid(validator1);
        assertFalse(isValid, "Validator should be detected as slashing");

        // Simulate inactivity
        vm.roll(block.number + 11); // Move forward 11 blocks
        isValid = trap.isValid(validator1);
        assertFalse(isValid, "Validator should be detected as slashing due to inactivity");
    }

    function testResetValidatorData() public {
        trap.updateValidatorData(validator1, 1);
        trap.resetValidatorData(validator1);
        assertEq(trap.validatorSignatures(validator1), 0);
        assertEq(trap.lastActiveBlock(validator1), block.number);
    }

    function testMultipleValidators() public {
        trap.updateValidatorData(validator1, 1);
        trap.updateValidatorData(validator2, 1);
        
        // Check both validators
        assertTrue(trap.isValid(validator1), "Validator 1 should be valid");
        assertTrue(trap.isValid(validator2), "Validator 2 should be valid");
        
        // Trigger slashing for validator 1
        trap.updateValidatorData(validator1, 2); // Exceeding max signatures
        assertFalse(trap.isValid(validator1), "Validator 1 should be detected as slashing");
        assertTrue(trap.isValid(validator2), "Validator 2 should still be valid");
    }
}