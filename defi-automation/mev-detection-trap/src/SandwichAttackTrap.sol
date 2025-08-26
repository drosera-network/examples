// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ITrap} from "./interfaces/ITrap.sol";

/**
 * @title SandwichAttackTrap
 * @notice Specialized trap for detecting sandwich attacks with advanced pattern recognition
 * @dev Monitors transaction mempools and block patterns to identify sandwich attacks
 */
contract SandwichAttackTrap is ITrap {
    
    uint256 constant MIN_PRICE_IMPACT = 0.1e18; // 10% minimum price impact
    uint256 constant MAX_TIME_BETWEEN_TXS = 3; // 3 seconds max between transactions
    uint256 constant MIN_VOLUME_RATIO = 5; // Middle trade must be 5x larger than surrounding
    uint256 constant SUSPICIOUS_GAS_MULTIPLIER = 2; // Gas price must be 2x higher than average
    
    struct SandwichData {
        uint256 blockNumber;
        uint256 timestamp;
        address targetAddress;
        uint256[] transactionVolumes;
        uint256[] priceImpacts;
        uint256[] gasPrices;
        address[] transactionSenders;
        uint256 estimatedProfit;
        bool isSandwichAttack;
    }
    
    struct SandwichAlert {
        uint256 blockNumber;
        uint256 timestamp;
        address targetAddress;
        address[] attackers;
        uint256 estimatedProfit;
        uint256 priceImpact;
        uint256 gasUsed;
    }
    
    address[] public monitoredAddresses;
    mapping(address => bool) public isMonitored;
    
    struct HistoricalData {
        uint256[] volumes;
        uint256[] prices;
        uint256[] gasPrices;
        uint256[] timestamps;
        uint256 index;
        uint256 maxEntries;
    }
    
    mapping(address => HistoricalData) public historicalData;
    
    constructor() {
        // Initialize with popular DEX pairs
        _addMonitoredAddress(0xB4e16d0168e52d35CaCD2c6185b44281eC28C9Dc); // Example pair
        _addMonitoredAddress(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852); // Example pair
        _addMonitoredAddress(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11); // Example pair
    }
    
    function collect() external view override returns (bytes memory) {
        SandwichData[] memory sandwichDataArray = new SandwichData[](monitoredAddresses.length);
        
        for (uint256 i = 0; i < monitoredAddresses.length; i++) {
            address target = monitoredAddresses[i];
            if (!isMonitored[target]) continue;
            
            sandwichDataArray[i] = _collectAddressData(target);
        }
        
        return abi.encode(sandwichDataArray);
    }
    
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool shouldTrigger, bytes memory responseData) {
        if (data.length < 3) {
            return (false, "");
        }
        
        SandwichData[][] memory allData = new SandwichData[][](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            allData[i] = abi.decode(data[i], (SandwichData[]));
        }
        
        SandwichAlert[] memory alerts = _analyzeSandwichPatterns(allData);
        
        if (alerts.length > 0) {
            return (true, abi.encode(alerts));
        }
        
        return (false, "");
    }
    
    function _collectAddressData(address target) internal view returns (SandwichData memory) {
        HistoricalData memory hist = historicalData[target];
        
        SandwichData memory data = SandwichData({
            blockNumber: block.number,
            timestamp: block.timestamp,
            targetAddress: target,
            transactionVolumes: new uint256[](0),
            priceImpacts: new uint256[](0),
            gasPrices: new uint256[](0),
            transactionSenders: new address[](0),
            estimatedProfit: 0,
            isSandwichAttack: false
        });
        
        // In a real implementation, this would collect data from:
        // 1. Mempool transactions
        // 2. Recent block transactions
        // 3. Price feeds
        // 4. Volume data
        
        // For now, return mock data structure
        return data;
    }
    
    function _analyzeSandwichPatterns(
        SandwichData[][] memory allData
    ) internal pure returns (SandwichAlert[] memory) {
        SandwichAlert[] memory alerts = new SandwichAlert[](100); // Max 100 alerts
        uint256 alertCount = 0;
        
        for (uint256 i = 0; i < allData.length; i++) {
            for (uint256 j = 0; j < allData[i].length; j++) {
                SandwichData memory data = allData[i][j];
                
                if (_isSandwichAttack(data)) {
                    alerts[alertCount++] = _createSandwichAlert(data);
                    
                    if (alertCount >= 100) break; 
                }
            }
        }
        
        // Resize array to actual alert count
        SandwichAlert[] memory finalAlerts = new SandwichAlert[](alertCount);
        for (uint256 i = 0; i < alertCount; i++) {
            finalAlerts[i] = alerts[i];
        }
        
        return finalAlerts;
    }
    
    function _isSandwichAttack(SandwichData memory data) internal pure returns (bool) {
        if (data.transactionVolumes.length < 3) return false;
        
        uint256 frontRunVolume = data.transactionVolumes[0];
        uint256 victimVolume = data.transactionVolumes[1];
        uint256 backRunVolume = data.transactionVolumes[2];
        
        if (victimVolume < frontRunVolume * MIN_VOLUME_RATIO || 
            victimVolume < backRunVolume * MIN_VOLUME_RATIO) {
            return false;
        }
        
        uint256 totalPriceImpact = 0;
        for (uint256 i = 0; i < data.priceImpacts.length; i++) {
            totalPriceImpact += data.priceImpacts[i];
        }
        
        if (totalPriceImpact < MIN_PRICE_IMPACT) {
            return false;
        }
        
        if (data.transactionVolumes.length >= 3) {
            // This would check actual transaction timestamps in real implementation
            return true;
        }
        
        return false;
    }
    
    function _createSandwichAlert(
        SandwichData memory data
    ) internal pure returns (SandwichAlert memory) {
        address[] memory attackers = new address[](2);
        attackers[0] = address(0); // Front-run attacker
        attackers[1] = address(0); // Back-run attacker
        
        uint256 totalPriceImpact = 0;
        for (uint256 i = 0; i < data.priceImpacts.length; i++) {
            totalPriceImpact += data.priceImpacts[i];
        }
        
        uint256 totalGas = 0;
        for (uint256 i = 0; i < data.gasPrices.length; i++) {
            totalGas += data.gasPrices[i];
        }
        
        return SandwichAlert({
            blockNumber: data.blockNumber,
            timestamp: data.timestamp,
            targetAddress: data.targetAddress,
            attackers: attackers,
            estimatedProfit: data.estimatedProfit,
            priceImpact: totalPriceImpact,
            gasUsed: totalGas
        });
    }
    
    
    function _detectGasPriceSpikes(
        uint256[] memory gasPrices
    ) internal pure returns (bool) {
        if (gasPrices.length < 2) return false;
        
        uint256 avgGas = 0;
        for (uint256 i = 0; i < gasPrices.length; i++) {
            avgGas += gasPrices[i];
        }
        avgGas = avgGas / gasPrices.length;
        
        for (uint256 i = 0; i < gasPrices.length; i++) {
            if (gasPrices[i] > avgGas * SUSPICIOUS_GAS_MULTIPLIER) {
                return true;
            }
        }
        
        return false;
    }
    
    function _detectVolumeAnomalies(
        uint256[] memory volumes
    ) internal pure returns (bool) {
        if (volumes.length < 3) return false;
        
        uint256 avgVolume = 0;
        for (uint256 i = 0; i < volumes.length; i++) {
            avgVolume += volumes[i];
        }
        avgVolume = avgVolume / volumes.length;
        
        uint256 anomalyCount = 0;
        for (uint256 i = 0; i < volumes.length; i++) {
            if (volumes[i] > avgVolume * 3 || volumes[i] < avgVolume / 3) {
                anomalyCount++;
            }
        }
        
        // If more than 50% of volumes are suspicious, flag it
        return anomalyCount > volumes.length / 2;
    }
    
    function _detectTimingPatterns(
        uint256[] memory timestamps
    ) internal pure returns (bool) {
        if (timestamps.length < 2) return false;
        
        for (uint256 i = 1; i < timestamps.length; i++) {
            if (timestamps[i] - timestamps[i-1] < MAX_TIME_BETWEEN_TXS) {
                return true;
            }
        }
        
        return false;
    }
    
    // Admin functions
    
    function addMonitoredAddress(address target) external {
        if (!isMonitored[target]) {
            monitoredAddresses.push(target);
            isMonitored[target] = true;
            
            historicalData[target] = HistoricalData({
                volumes: new uint256[](100),
                prices: new uint256[](100),
                gasPrices: new uint256[](100),
                timestamps: new uint256[](100),
                index: 0,
                maxEntries: 100
            });
        }
    }
    
    function removeMonitoredAddress(address target) external {
        if (isMonitored[target]) {
            isMonitored[target] = false;
        }
    }
    
    function updateHistoricalData(
        address target,
        uint256 volume,
        uint256 price,
        uint256 gasPrice
    ) external {
        if (!isMonitored[target]) return;
        
        HistoricalData storage hist = historicalData[target];
        
        hist.volumes[hist.index] = volume;
        hist.prices[hist.index] = price;
        hist.gasPrices[hist.index] = gasPrice;
        hist.timestamps[hist.index] = block.timestamp;
        
        hist.index = (hist.index + 1) % hist.maxEntries;
    }


    function getMonitoredAddresses() external view returns (address[] memory) {
        return monitoredAddresses;
    }
    
    function getHistoricalData(
        address target
    ) external view returns (HistoricalData memory) {
        return historicalData[target];
    }
    
    function getThresholds() external pure returns (
        uint256 minPriceImpact,
        uint256 maxTimeBetweenTxs,
        uint256 minVolumeRatio,
        uint256 suspiciousGasMultiplier
    ) {
        return (
            MIN_PRICE_IMPACT,
            MAX_TIME_BETWEEN_TXS,
            MIN_VOLUME_RATIO,
            SUSPICIOUS_GAS_MULTIPLIER
        );
    }
    
    function estimateSandwichProfit(
        uint256[] memory volumes,
        uint256[] memory priceImpacts
    ) external pure returns (uint256) {
        if (volumes.length != priceImpacts.length || volumes.length < 3) {
            return 0;
        }
        
        uint256 frontRunProfit = (volumes[0] * priceImpacts[0]) / 1e18;
        uint256 backRunProfit = (volumes[2] * priceImpacts[2]) / 1e18;
        
        return frontRunProfit + backRunProfit;
    }
    
    function _addMonitoredAddress(address target) internal {
        if (!isMonitored[target]) {
            monitoredAddresses.push(target);
            isMonitored[target] = true;
            
            historicalData[target] = HistoricalData({
                volumes: new uint256[](100),
                prices: new uint256[](100),
                gasPrices: new uint256[](100),
                timestamps: new uint256[](100),
                index: 0,
                maxEntries: 100
            });
        }
    }
}
