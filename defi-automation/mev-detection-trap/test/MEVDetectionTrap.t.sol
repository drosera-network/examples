// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {MEVDetectionTrap} from "../src/MEVDetectionTrap.sol";
import {SandwichAttackTrap} from "../src/SandwichAttackTrap.sol";
import {MEVResponse} from "../src/MEVResponse.sol";

contract MEVDetectionTrapTest is Test {
    MEVDetectionTrap public mevTrap;
    SandwichAttackTrap public sandwichTrap;
    MEVResponse public mevResponse;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public mevBot = address(0x3);
    address public dex1 = address(0x4);
    address public dex2 = address(0x5);
    
    function setUp() public {
        mevTrap = new MEVDetectionTrap();
        sandwichTrap = new SandwichAttackTrap();
        mevResponse = new MEVResponse(address(0x123)); // Mock trap config
        
        // Fund test addresses
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(mevBot, 100 ether);
    }
    
    // Test MEVDetectionTrap
    
    function testConstructor() public {
        address[] memory dexes = mevTrap.getMonitoredDEXs();
        assertEq(dexes.length, 3); // Should have 3 DEXs initialized
        
        address[] memory bots = mevTrap.getKnownMEVBots();
        assertEq(bots.length, 1); // Should have 1 bot initialized
    }
    
    function testCollectFunction() public {
        bytes memory data = mevTrap.collect();
        assertGt(data.length, 0, "Collect should return data");
        
        MEVDetectionTrap.MEVData memory mevData = abi.decode(data, (MEVDetectionTrap.MEVData));
        assertEq(mevData.blockNumber, block.number);
        assertEq(mevData.dexAddresses.length, 3);
    }
    
    function testShouldRespondWithNoData() public {
        bytes[] memory emptyData = new bytes[](0);
        (bool shouldTrigger, bytes memory responseData) = mevTrap.shouldRespond(emptyData);
        
        assertFalse(shouldTrigger, "Should not trigger with no data");
        assertEq(responseData.length, 0, "Response data should be empty");
    }
    
    function testShouldRespondWithInsufficientData() public {
        bytes[] memory insufficientData = new bytes[](1);
        insufficientData[0] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number,
            timestamp: block.timestamp,
            dexAddresses: new address[](1),
            prices: new uint256[](1),
            volumes: new uint256[](1),
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        (bool shouldTrigger, bytes memory responseData) = mevTrap.shouldRespond(insufficientData);
        
        assertFalse(shouldTrigger, "Should not trigger with insufficient data");
        assertEq(responseData.length, 0, "Response data should be empty");
    }
    
    function testSandwichAttackDetection() public {
        // Create mock data that simulates a sandwich attack
        bytes[] memory sandwichData = new bytes[](3);
        
        // Block 1: Small trade
        sandwichData[0] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number - 2,
            timestamp: block.timestamp - 2,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(100e18), // Small volume
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        // Block 2: Large trade (victim)
        sandwichData[1] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number - 1,
            timestamp: block.timestamp - 1,
            dexAddresses: new address[](1),
            prices: _toArray(1500e18), // Price impact
            volumes: _toArray(1000e18), // Large volume (10x)
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        // Block 3: Small trade
        sandwichData[2] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number,
            timestamp: block.timestamp,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(100e18), // Small volume
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        (bool shouldTrigger, bytes memory responseData) = mevTrap.shouldRespond(sandwichData);
        
        assertTrue(shouldTrigger, "Should detect sandwich attack");
        assertGt(responseData.length, 0, "Should return response data");
        
        // Decode and verify alert
        MEVDetectionTrap.MEVAlert memory alert = abi.decode(responseData, (MEVDetectionTrap.MEVAlert));
        assertEq(uint256(alert.mevType), uint256(MEVDetectionTrap.MEVType.SANDWICH_ATTACK));
        assertGt(alert.estimatedProfit, 0, "Should estimate profit");
    }
    
    function testArbitrageOpportunityDetection() public {
        // Create mock data that simulates arbitrage opportunity
        bytes[] memory arbitrageData = new bytes[](2);
        
        // DEX 1: Higher price
        arbitrageData[0] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number - 1,
            timestamp: block.timestamp - 1,
            dexAddresses: new address[](1),
            prices: _toArray(1100e18), // 10% higher
            volumes: _toArray(500e18),
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        // DEX 2: Lower price
        arbitrageData[1] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number,
            timestamp: block.timestamp,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18), // Base price
            volumes: _toArray(500e18),
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        (bool shouldTrigger, bytes memory responseData) = mevTrap.shouldRespond(arbitrageData);
        
        assertTrue(shouldTrigger, "Should detect arbitrage opportunity");
        assertGt(responseData.length, 0, "Should return response data");
        
        // Decode and verify alert
        MEVDetectionTrap.MEVAlert memory alert = abi.decode(responseData, (MEVDetectionTrap.MEVAlert));
        assertEq(uint256(alert.mevType), uint256(MEVDetectionTrap.MEVType.ARBITRAGE_OPPORTUNITY));
    }
    
    function testMEVBotActivityDetection() public {
        // Create mock data that simulates MEV bot activity
        bytes[] memory mevBotData = new bytes[](2);
        
        // Block 1: Normal gas
        mevBotData[0] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number - 1,
            timestamp: block.timestamp - 2,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(500e18),
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        // Block 2: High gas, rapid succession
        mevBotData[1] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number,
            timestamp: block.timestamp - 1, // 1 second later
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(500e18),
            gasPrice: 2000 gwei, // 100x higher gas
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        (bool shouldTrigger, bytes memory responseData) = mevTrap.shouldRespond(mevBotData);
        
        assertTrue(shouldTrigger, "Should detect MEV bot activity");
        assertGt(responseData.length, 0, "Should return response data");
        
        // Decode and verify alert
        MEVDetectionTrap.MEVAlert memory alert = abi.decode(responseData, (MEVDetectionTrap.MEVAlert));
        assertEq(uint256(alert.mevType), uint256(MEVDetectionTrap.MEVType.MEV_BOT_ACTIVITY));
    }
    
    function testSuspiciousPatternDetection() public {
        // Create mock data that simulates suspicious patterns
        bytes[] memory suspiciousData = new bytes[](3);
        
        // Block 1: Normal volume
        suspiciousData[0] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number - 2,
            timestamp: block.timestamp - 2,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(100e18), // Normal volume
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        // Block 2: Normal volume
        suspiciousData[1] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number - 1,
            timestamp: block.timestamp - 1,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(100e18), // Normal volume
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        // Block 3: Extremely high volume (10x normal)
        suspiciousData[2] = abi.encode(MEVDetectionTrap.MEVData({
            blockNumber: block.number,
            timestamp: block.timestamp,
            dexAddresses: new address[](1),
            prices: _toArray(1000e18),
            volumes: _toArray(1000e18), // 10x normal volume
            gasPrice: 20 gwei,
            suspiciousAddresses: new address[](0),
            mevType: MEVDetectionTrap.MEVType.NONE,
            estimatedProfit: 0
        }));
        
        (bool shouldTrigger, bytes memory responseData) = mevTrap.shouldRespond(suspiciousData);
        
        assertTrue(shouldTrigger, "Should detect suspicious pattern");
        assertGt(responseData.length, 0, "Should return response data");
        
        // Decode and verify alert
        MEVDetectionTrap.MEVAlert memory alert = abi.decode(responseData, (MEVDetectionTrap.MEVAlert));
        assertEq(uint256(alert.mevType), uint256(MEVDetectionTrap.MEVType.SUSPICIOUS_PATTERN));
    }
    
    function testAddRemoveMonitoredDEX() public {
        address newDEX = address(0x999);
        
        // Add new DEX
        mevTrap.addMonitoredDEX(newDEX);
        address[] memory dexes = mevTrap.getMonitoredDEXs();
        assertEq(dexes.length, 4); // Should now have 4 DEXs
        
        // Remove DEX (marks as not monitored)
        mevTrap.removeMonitoredDEX(newDEX);
        // Note: This doesn't remove from array, just marks as not monitored
    }
    
    function testAddRemoveKnownMEVBot() public {
        address newBot = address(0x888);
        
        // Add new bot
        mevTrap.addKnownMEVBot(newBot);
        address[] memory bots = mevTrap.getKnownMEVBots();
        assertEq(bots.length, 2); // Should now have 2 bots
        
        // Remove bot
        mevTrap.removeKnownMEVBot(newBot);
    }
    
    function testGetThresholds() public {
        (
            uint256 sandwichThreshold,
            uint256 arbitrageThreshold,
            uint256 mevProfitThreshold,
            uint256 suspiciousGasThreshold
        ) = mevTrap.getThresholds();
        
        assertEq(sandwichThreshold, 0.5e18, "Sandwich threshold should be 50%");
        assertEq(arbitrageThreshold, 0.02e18, "Arbitrage threshold should be 2%");
        assertEq(mevProfitThreshold, 0.1e18, "MEV profit threshold should be 0.1 ETH");
        assertEq(suspiciousGasThreshold, 1000, "Suspicious gas threshold should be 1000 gwei");
    }
    
    // Test SandwichAttackTrap
    
    function testSandwichAttackTrapConstructor() public {
        address[] memory addresses = sandwichTrap.getMonitoredAddresses();
        assertEq(addresses.length, 3); // Should have 3 addresses initialized
    }
    
    function testSandwichAttackTrapCollect() public {
        bytes memory data = sandwichTrap.collect();
        assertGt(data.length, 0, "Collect should return data");
        
        // Decode and verify data structure
        SandwichAttackTrap.SandwichData[] memory sandwichDataArray = abi.decode(data, (SandwichAttackTrap.SandwichData[]));
        assertEq(sandwichDataArray.length, 3);
    }
    
    function testSandwichAttackTrapShouldRespond() public {
        // Create mock sandwich attack data
        bytes[] memory sandwichData = new bytes[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            sandwichData[i] = abi.encode(SandwichAttackTrap.SandwichData({
                blockNumber: block.number - 2 + i,
                timestamp: block.timestamp - 2 + i,
                targetAddress: address(0x123),
                transactionVolumes: _toArray(100e18 + i * 50e18),
                priceImpacts: _toArray(0.05e18 + i * 0.02e18),
                gasPrices: _toArray(20 gwei + i * 5 gwei),
                transactionSenders: new address[](0),
                estimatedProfit: 0,
                isSandwichAttack: false
            }));
        }
        
        (bool shouldTrigger, bytes memory responseData) = sandwichTrap.shouldRespond(sandwichData);
        console2.log("Sandwich trap response:", shouldTrigger);
    }
    
    function testSandwichAttackTrapAddRemoveAddress() public {
        address newAddress = address(0x777);
        
        // Add new address
        sandwichTrap.addMonitoredAddress(newAddress);
        address[] memory addresses = sandwichTrap.getMonitoredAddresses();
        assertEq(addresses.length, 4);
        
        // Remove address
        sandwichTrap.removeMonitoredAddress(newAddress);
    }
    
    function testSandwichAttackTrapUpdateHistoricalData() public {
        address target = address(0x123);
        sandwichTrap.addMonitoredAddress(target);
        
        sandwichTrap.updateHistoricalData(target, 1000e18, 1000e18, 20 gwei);
        
        SandwichAttackTrap.HistoricalData memory hist = sandwichTrap.getHistoricalData(target);
        assertEq(hist.volumes[0], 1000e18);
        assertEq(hist.prices[0], 1000e18);
        assertEq(hist.gasPrices[0], 20 gwei);
    }
    
    function testSandwichAttackTrapGetThresholds() public {
        (
            uint256 minPriceImpact,
            uint256 maxTimeBetweenTxs,
            uint256 minVolumeRatio,
            uint256 suspiciousGasMultiplier
        ) = sandwichTrap.getThresholds();
        
        assertEq(minPriceImpact, 0.1e18, "Min price impact should be 10%");
        assertEq(maxTimeBetweenTxs, 3, "Max time between txs should be 3 seconds");
        assertEq(minVolumeRatio, 5, "Min volume ratio should be 5x");
        assertEq(suspiciousGasMultiplier, 2, "Suspicious gas multiplier should be 2x");
    }
    
    function testSandwichAttackTrapEstimateProfit() public {
        uint256[] memory volumes = new uint256[](3);
        volumes[0] = 100e18;  // Front-run
        volumes[1] = 1000e18; // Victim
        volumes[2] = 100e18;  // Back-run
        
        uint256[] memory priceImpacts = new uint256[](3);
        priceImpacts[0] = 0.05e18;  // 5% impact
        priceImpacts[1] = 0.10e18;  // 10% impact
        priceImpacts[2] = 0.05e18;  // 5% impact
        
        uint256 profit = sandwichTrap.estimateSandwichProfit(volumes, priceImpacts);
        assertGt(profit, 0, "Should calculate profit");
    }
    
    // Test MEVResponse
    
    function testMEVResponseConstructor() public {
        assertEq(mevResponse.trapConfig(), address(0x123));
        assertFalse(mevResponse.emergencyPaused());
    }
    
    function testMEVResponseGetResponseConfig() public {
        MEVResponse.ResponseConfig memory config = mevResponse.getResponseConfig(MEVDetectionTrap.MEVType.SANDWICH_ATTACK);
        assertTrue(config.enabled);
        assertEq(config.cooldownPeriod, 300); // 5 minutes
        assertEq(config.maxExecutionsPerHour, 10);
    }
    
    function testMEVResponseEmergencyPause() public {
        // Only emergency pauser can pause
        vm.prank(user1);
        vm.expectRevert("Only emergency pauser can call this");
        mevResponse.emergencyPause();
        
        // Emergency pauser can pause
        vm.prank(address(0x123)); // trap config
        mevResponse.emergencyPause();
        assertTrue(mevResponse.emergencyPaused());
        
        // Emergency pauser can unpause
        vm.prank(address(0x123));
        mevResponse.emergencyUnpause();
        assertFalse(mevResponse.emergencyPaused());
    }
    
    function testMEVResponseGetResponseStatus() public {
        (
            bool paused,
            uint256 totalProcessedAlerts,
            bool[] memory enabledResponses
        ) = mevResponse.getResponseStatus();
        
        assertFalse(paused);
        assertEq(enabledResponses.length, 4);
        assertTrue(enabledResponses[0]); // Sandwich attack
        assertTrue(enabledResponses[1]); // Arbitrage opportunity
        assertTrue(enabledResponses[2]); // MEV bot activity
        assertTrue(enabledResponses[3]); // Suspicious pattern
    }
        
    function _toArray(uint256 value) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = value;
        return array;
    }
    
    function _toArray(address value) internal pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = value;
        return array;
    }
}
