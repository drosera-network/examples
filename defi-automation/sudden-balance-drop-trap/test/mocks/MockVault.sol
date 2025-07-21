// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title MockVault
 * @notice Mock vault contract that holds USDC and can be paused or frozen
 * @dev Used for testing the response contract's pause and circuit breaker functionality
 */
contract MockVault {
    bool public paused;
    address public guardian;
    address public owner;
    IERC20 public immutable usdcToken;
    
    // Circuit breaker state
    uint256 public withdrawalFreezeUntil;
    uint256 public constant CIRCUIT_BREAKER_BLOCKS = 32;

    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event CircuitBreakerActivated(uint256 freezeUntilBlock);
    event EmergencyTransfer(address indexed to, uint256 amount);

    modifier whenNotPaused() {
        require(!paused, "Vault is paused");
        require(block.number >= withdrawalFreezeUntil, "Vault is frozen by circuit breaker");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only guardian can call");
        _;
    }

    constructor(address _usdcToken, address _guardian) {
        usdcToken = IERC20(_usdcToken);
        guardian = _guardian;
        owner = msg.sender; // Set deployer as owner
    }

    /**
     * @notice Pause the vault - callable by guardian (response contract)
     */
    function pause() external onlyGuardian {
        require(!paused, "Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpause the vault - callable by guardian
     */
    function unpause() external onlyGuardian {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    /**
     * @notice Activate circuit breaker to freeze withdrawals for 32 blocks
     * @dev Alternative to pausing - provides automatic recovery after time period
     */
    function activateCircuitBreaker() external onlyGuardian {
        withdrawalFreezeUntil = block.number + CIRCUIT_BREAKER_BLOCKS;
        emit CircuitBreakerActivated(withdrawalFreezeUntil);
    }
    
    /**
     * @notice Check if circuit breaker is currently active
     */
    function isCircuitBreakerActive() external view returns (bool) {
        return block.number < withdrawalFreezeUntil;
    }

    /**
     * @notice Withdraw USDC from the vault - blocked when paused
     * @param amount The amount of USDC to withdraw
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Invalid amount");
        require(usdcToken.balanceOf(address(this)) >= amount, "Insufficient balance");
        
        // Transfer tokens to the caller
        bool success = usdcToken.transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }

    /**
     * @notice Emergency transfer all funds to owner - callable by guardian
     * @dev Used as an emergency protection mechanism
     */
    function emergencyTransferToOwner() external onlyGuardian {
        uint256 balance = usdcToken.balanceOf(address(this));
        require(balance > 0, "No balance to transfer");
        
        bool success = usdcToken.transfer(owner, balance);
        require(success, "Transfer failed");
        
        emit EmergencyTransfer(owner, balance);
    }
    
    /**
     * @notice Get current USDC balance
     */
    function getBalance() external view returns (uint256) {
        return usdcToken.balanceOf(address(this));
    }
}
