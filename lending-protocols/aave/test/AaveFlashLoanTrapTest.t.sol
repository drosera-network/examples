// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/AaveFlashLoanTrap.sol";
import "../src/AaveLikeProtocol.sol";

contract AaveFlashLoanTrapTest is Test {
    AaveLikeProtocol public aave;
     AaveFlashLoanTrap public trap;

    function setUp() public {
        aave = new AaveLikeProtocol(address(this)); // Deploy the Aave-like protocol
        trap = new  AaveFlashLoanTrap(address(aave)); // Deploy the trap contract
        aave.setLiquidity(1000); // Initialize the protocol with some liquidity
        aave.setTrapContract(trap);
        console.log("Setup completed: AaveLikeProtocol deployed with liquidity 1000 and AaveFlashLoanTrap deployed.");
    }

    function testCollect() public view {
         AaveFlashLoanTrap.LiquidityInfo memory data = trap.collect();
        console.log("Collected available liquidity:", data.availableLiquidity);
        assertGt(data.availableLiquidity, 0, "Available liquidity should be greater than 0");
    }

    function testIsValid() public {
        AaveFlashLoanTrap.LiquidityInfo[] memory dataPoints = new  AaveFlashLoanTrap.LiquidityInfo[](2);
        dataPoints[0] =  AaveFlashLoanTrap.LiquidityInfo({availableLiquidity: 1000});
        dataPoints[1] =  AaveFlashLoanTrap.LiquidityInfo({availableLiquidity: 850});

        console.log("Data points set: [1000, 850]");
        console.log("Calling isValid...");
        bool result = trap.isValid(dataPoints);
        console.log("isValid result:", result);

        console.log("Checking if protocol is paused...");
        assertEq(result, false, "Liquidity decrease more than 10% should be invalid");
        console.log("Protocol paused: ",aave.paused());
        assertEq(aave.paused(), true, "Protocol should be paused");
    }

    function testIsValidWithNoPause() public {
         AaveFlashLoanTrap.LiquidityInfo[] memory dataPoints = new  AaveFlashLoanTrap.LiquidityInfo[](2);
        dataPoints[0] =  AaveFlashLoanTrap.LiquidityInfo({availableLiquidity: 1000});
        dataPoints[1] =  AaveFlashLoanTrap.LiquidityInfo({availableLiquidity: 950});

        console.log("Data points set: [1000, 950]");
        console.log("Calling isValid...");
        bool result = trap.isValid(dataPoints);
        console.log("isValid result:", result);

        console.log("Checking if protocol is paused...");
        assertEq(result, true, "No significant liquidity decrease should be valid");
        console.log("Protocol paused: ",aave.paused());
        assertEq(aave.paused(), false, "Protocol should not be paused");
    }
}
