// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MEVDetectionTrap} from "./MEVDetectionTrap.sol";

/**
 * @title MEVResponse
 * @notice Response contract for handling MEV detection alerts
 * @dev Implements various response strategies for different types of MEV activities
 */
contract MEVResponse {
    
    // Events for different response types
    event SandwichAttackDetected(
        uint256 indexed blockNumber,
        uint256 timestamp,
        address[] involvedAddresses,
        uint256 estimatedProfit
    );
    
    event ArbitrageOpportunityDetected(
        uint256 indexed blockNumber,
        uint256 timestamp,
        address[] involvedAddresses,
        uint256 estimatedProfit
    );
    
    event MEVBotActivityDetected(
        uint256 indexed blockNumber,
        uint256 timestamp,
        address[] involvedAddresses
    );
    
    event SuspiciousPatternDetected(
        uint256 indexed blockNumber,
        uint256 timestamp,
        address[] involvedAddresses
    );
    
    event ResponseExecuted(
        uint256 indexed blockNumber,
        MEVDetectionTrap.MEVType mevType,
        bytes responseData
    );
    
    address public trapConfig;
    mapping(uint256 => bool) public processedAlerts;
    mapping(MEVDetectionTrap.MEVType => bool) public enabledResponses;
    
    struct ResponseConfig {
        bool enabled;
        uint256 cooldownPeriod;
        uint256 lastExecution;
        uint256 maxExecutionsPerHour;
        uint256 executionCount;
        uint256 lastResetTime;
    }
    
    mapping(MEVDetectionTrap.MEVType => ResponseConfig) public responseConfigs;
    
    bool public emergencyPaused;
    address public emergencyPauser;
    
    constructor(address _trapConfig) {
        trapConfig = _trapConfig;
        emergencyPauser = msg.sender;
        
        _initializeResponseConfigs();
    }
    
    modifier onlyTrapConfig() {
        require(msg.sender == trapConfig, "Only TrapConfig can call this");
        _;
    }
    
    modifier onlyEmergencyPauser() {
        require(msg.sender == emergencyPauser, "Only emergency pauser can call this");
        _;
    }
    
    modifier whenNotPaused() {
        require(!emergencyPaused, "Contract is emergency paused");
        _;
    }
    
    function _initializeResponseConfigs() internal {
        // Sandwich attack response config
        responseConfigs[MEVDetectionTrap.MEVType.SANDWICH_ATTACK] = ResponseConfig({
            enabled: true,
            cooldownPeriod: 300, // 5 minutes
            lastExecution: 0,
            maxExecutionsPerHour: 10,
            executionCount: 0,
            lastResetTime: block.timestamp
        });
        
        // Arbitrage opportunity response config
        responseConfigs[MEVDetectionTrap.MEVType.ARBITRAGE_OPPORTUNITY] = ResponseConfig({
            enabled: true,
            cooldownPeriod: 60, // 1 minute
            lastExecution: 0,
            maxExecutionsPerHour: 20,
            executionCount: 0,
            lastResetTime: block.timestamp
        });
        
        // MEV bot activity response config
        responseConfigs[MEVDetectionTrap.MEVType.MEV_BOT_ACTIVITY] = ResponseConfig({
            enabled: true,
            cooldownPeriod: 120, // 2 minutes
            lastExecution: 0,
            maxExecutionsPerHour: 15,
            executionCount: 0,
            lastResetTime: block.timestamp
        });
        
        // Suspicious pattern response config
        responseConfigs[MEVDetectionTrap.MEVType.SUSPICIOUS_PATTERN] = ResponseConfig({
            enabled: true,
            cooldownPeriod: 180, // 3 minutes
            lastExecution: 0,
            maxExecutionsPerHour: 12,
            executionCount: 0,
            lastResetTime: block.timestamp
        });
    }
    
    /**
     * @notice Main response function called by the Drosera Protocol
     * @param alertData Encoded MEV alert data from the trap
     * @dev This function matches the response_function signature in drosera.toml
     */
    function handleMEVAlert(bytes calldata alertData) external onlyTrapConfig whenNotPaused {
        MEVDetectionTrap.MEVAlert memory alert = abi.decode(alertData, (MEVDetectionTrap.MEVAlert));
        
        // Check if alert was already processed
        require(!processedAlerts[alert.blockNumber], "Alert already processed");
        
        // Mark alert as processed
        processedAlerts[alert.blockNumber] = true;
        
        // Check if response is enabled and within limits
        require(_canExecuteResponse(alert.mevType), "Response not available");
        
        // Update execution tracking
        _updateExecutionTracking(alert.mevType);
        
        // Execute appropriate response based on MEV type
        bytes memory responseData = _executeResponse(alert);
        
        // Emit events
        _emitAlertEvents(alert);
        emit ResponseExecuted(alert.blockNumber, alert.mevType, responseData);
    }
    
    function _canExecuteResponse(MEVDetectionTrap.MEVType mevType) internal view returns (bool) {
        ResponseConfig memory config = responseConfigs[mevType];
        
        if (!config.enabled) return false;
        if (block.timestamp < config.lastExecution + config.cooldownPeriod) return false;
        
        if (block.timestamp >= config.lastResetTime + 3600) {
            // Reset hourly counter
            return true;
        }
        
        return config.executionCount < config.maxExecutionsPerHour;
    }
    
    function _updateExecutionTracking(MEVDetectionTrap.MEVType mevType) internal {
        ResponseConfig storage config = responseConfigs[mevType];
        
        if (block.timestamp >= config.lastResetTime + 3600) {
            config.executionCount = 0;
            config.lastResetTime = block.timestamp;
        }
        
        config.lastExecution = block.timestamp;
        config.executionCount++;
    }
    
    function _executeResponse(
        MEVDetectionTrap.MEVAlert memory alert
    ) internal returns (bytes memory) {
        if (alert.mevType == MEVDetectionTrap.MEVType.SANDWICH_ATTACK) {
            return _handleSandwichAttack(alert);
        } else if (alert.mevType == MEVDetectionTrap.MEVType.ARBITRAGE_OPPORTUNITY) {
            return _handleArbitrageOpportunity(alert);
        } else if (alert.mevType == MEVDetectionTrap.MEVType.MEV_BOT_ACTIVITY) {
            return _handleMEVBotActivity(alert);
        } else if (alert.mevType == MEVDetectionTrap.MEVType.SUSPICIOUS_PATTERN) {
            return _handleSuspiciousPattern(alert);
        }
        
        return "";
    }
    
    function _handleSandwichAttack(
        MEVDetectionTrap.MEVAlert memory alert
    ) internal returns (bytes memory) { 
        return abi.encode(
            "SANDWICH_RESPONSE",
            alert.involvedAddresses,
            alert.estimatedProfit,
            block.timestamp
        );
    }
    
    function _handleArbitrageOpportunity(
        MEVDetectionTrap.MEVAlert memory alert
    ) internal returns (bytes memory) {
        return abi.encode(
            "ARBITRAGE_RESPONSE",
            alert.involvedAddresses,
            alert.estimatedProfit,
            block.timestamp
        );
    }
    
    function _handleMEVBotActivity(
        MEVDetectionTrap.MEVAlert memory alert
    ) internal returns (bytes memory) {
        return abi.encode(
            "MEV_BOT_RESPONSE",
            alert.involvedAddresses,
            block.timestamp
        );
    }
    
    function _handleSuspiciousPattern(
        MEVDetectionTrap.MEVAlert memory alert
    ) internal returns (bytes memory) {
        return abi.encode(
            "SUSPICIOUS_PATTERN_RESPONSE",
            alert.involvedAddresses,
            block.timestamp
        );
    }
    
    function _emitAlertEvents(MEVDetectionTrap.MEVAlert memory alert) internal {
        if (alert.mevType == MEVDetectionTrap.MEVType.SANDWICH_ATTACK) {
            emit SandwichAttackDetected(
                alert.blockNumber,
                alert.timestamp,
                alert.involvedAddresses,
                alert.estimatedProfit
            );
        } else if (alert.mevType == MEVDetectionTrap.MEVType.ARBITRAGE_OPPORTUNITY) {
            emit ArbitrageOpportunityDetected(
                alert.blockNumber,
                alert.timestamp,
                alert.involvedAddresses,
                alert.estimatedProfit
            );
        } else if (alert.mevType == MEVDetectionTrap.MEVType.MEV_BOT_ACTIVITY) {
            emit MEVBotActivityDetected(
                alert.blockNumber,
                alert.timestamp,
                alert.involvedAddresses
            );
        } else if (alert.mevType == MEVDetectionTrap.MEVType.SUSPICIOUS_PATTERN) {
            emit SuspiciousPatternDetected(
                alert.blockNumber,
                alert.timestamp,
                alert.involvedAddresses
            );
        }
    }
    
    // Admin functions
    
    function setResponseConfig(
        MEVDetectionTrap.MEVType mevType,
        bool enabled,
        uint256 cooldownPeriod,
        uint256 maxExecutionsPerHour
    ) external onlyTrapConfig {
        ResponseConfig storage config = responseConfigs[mevType];
        config.enabled = enabled;
        config.cooldownPeriod = cooldownPeriod;
        config.maxExecutionsPerHour = maxExecutionsPerHour;
    }
    
    function emergencyPause() external onlyEmergencyPauser {
        emergencyPaused = true;
    }
    
    function emergencyUnpause() external onlyEmergencyPauser {
        emergencyPaused = false;
    }
    
    function transferEmergencyPauser(address newPauser) external onlyEmergencyPauser {
        emergencyPauser = newPauser;
    }


    function getResponseConfig(
        MEVDetectionTrap.MEVType mevType
    ) external view returns (ResponseConfig memory) {
        return responseConfigs[mevType];
    }
    
    function isAlertProcessed(uint256 blockNumber) external view returns (bool) {
        return processedAlerts[blockNumber];
    }
    
    function canExecuteResponse(MEVDetectionTrap.MEVType mevType) external view returns (bool) {
        return _canExecuteResponse(mevType);
    }
    
    function getResponseStatus() external view returns (
        bool paused,
        uint256 totalProcessedAlerts,
        bool[] memory responseStatuses
    ) {
        responseStatuses = new bool[](4);
        responseStatuses[0] = responseConfigs[MEVDetectionTrap.MEVType.SANDWICH_ATTACK].enabled;
        responseStatuses[1] = responseConfigs[MEVDetectionTrap.MEVType.ARBITRAGE_OPPORTUNITY].enabled;
        responseStatuses[2] = responseConfigs[MEVDetectionTrap.MEVType.MEV_BOT_ACTIVITY].enabled;
        responseStatuses[3] = responseConfigs[MEVDetectionTrap.MEVType.SUSPICIOUS_PATTERN].enabled;
        
        return (emergencyPaused, 0, responseStatuses);
    }
}
