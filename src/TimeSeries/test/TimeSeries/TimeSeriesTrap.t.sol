// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../../src/TimeSeries/TimeSeriesTrap.sol";

contract TimeSeriesTrapTest is Test {
    TimeSeriesTrap trap;
    
    function setUp() public {
        trap = new TimeSeriesTrap();
    }
    
    function testAnomalyDetection() public {
        uint256[] memory data = new uint256[](6);
        data[0] = 100;
        data[1] = 110;
        data[2] = 105;
        data[3] = 115;
        data[4] = 110;
        data[5] = 250; // Аномалия
        
        (bool result, ) = trap.shouldRespond(data);
        assertTrue(result);
    }
}
