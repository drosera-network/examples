// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISecuredVault {
    function pause() external;
    function activateCircuitBreaker() external;
    function emergencyTransferToOwner() external;
}

/**
 * @title SuddenBalanceDropResponse
 * @notice Response contract for handling sudden balance drop alerts
 */
contract SuddenBalanceDropResponse {
    event BalanceDropHandled(
        address indexed vault,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 timestamp
    );
    event VaultPaused(address indexed vault);
    event CircuitBreakerActivated(address indexed vault);
    event EmergencyTransferTriggered(address indexed vault);

    // State to track responses
    mapping(address => bool) public balanceDropHandled;

    // Simple access control
    address public trapConfig;

    constructor(address _trapConfig) {
        trapConfig = _trapConfig;
    }

    modifier onlyTrapConfig() {
        require(msg.sender == trapConfig, "Only TrapConfig can call this");
        _;
    }

    /**
     * @notice Handle a sudden balance drop - Event only
     * @param vault The vault address that experienced the drop
     * @param oldBalance The previous balance
     * @param newBalance The current balance
     * @dev This only emits an event for monitoring purposes
     */
    function handleBalanceDropWithEvent(
        address vault,
        uint256 oldBalance,
        uint256 newBalance
    ) external onlyTrapConfig {
        // Mark the vault as handled
        balanceDropHandled[vault] = true;
        emit BalanceDropHandled(vault, oldBalance, newBalance, block.timestamp);
    }
    
    /**
     * @notice Handle a sudden balance drop - Pause vault
     * @param vault The vault address that experienced the drop
     * @param oldBalance The previous balance
     * @param newBalance The current balance
     * @dev This emits an event and attempts to pause the vault
     */
    function handleBalanceDropWithPause(
        address vault,
        uint256 oldBalance,
        uint256 newBalance
    ) external onlyTrapConfig {
        // Mark the vault as handled
        balanceDropHandled[vault] = true;
        emit BalanceDropHandled(vault, oldBalance, newBalance, block.timestamp);
        
        // Attempt to pause the vault if it supports pausing
        try ISecuredVault(vault).pause() {
            emit VaultPaused(vault);
        } catch {
            // Vault doesn't support pausing or pause failed
        }
    }

    /**
     * @notice Activate circuit breaker for a vault (alternative to pausing)
     * @param vault The vault address that experienced the drop
     * @param oldBalance The previous balance
     * @param newBalance The current balance
     * @dev This provides a time-based freeze instead of indefinite pause
     */
    function handleBalanceDropWithCircuitBreaker(
        address vault,
        uint256 oldBalance,
        uint256 newBalance
    ) external onlyTrapConfig {
        // Mark the vault as handled
        balanceDropHandled[vault] = true;
        emit BalanceDropHandled(vault, oldBalance, newBalance, block.timestamp);

        // Activate the vault's circuit breaker
        try ISecuredVault(vault).activateCircuitBreaker() {
            emit CircuitBreakerActivated(vault);
        } catch {
            // Vault doesn't support circuit breaker or activation failed
        }
    }

    /**
     * @notice Transfer all vault funds to owner (emergency protection)
     * @param vault The vault address that experienced the drop
     * @param oldBalance The previous balance
     * @param newBalance The current balance
     * @dev This transfers all remaining funds to vault owner
     */
    function handleBalanceDropWithTransfer(
        address vault,
        uint256 oldBalance,
        uint256 newBalance
    ) external onlyTrapConfig {
        // Mark the vault as handled
        balanceDropHandled[vault] = true;
        emit BalanceDropHandled(vault, oldBalance, newBalance, block.timestamp);
        
        // Trigger emergency transfer to owner
        try ISecuredVault(vault).emergencyTransferToOwner() {
            emit EmergencyTransferTriggered(vault);
        } catch {
            // Vault doesn't support emergency transfer or transfer failed
        }
    }

    // View function for testing
    function wasBalanceDropHandled(address vault) external view returns (bool) {
        return balanceDropHandled[vault];
    }
}
