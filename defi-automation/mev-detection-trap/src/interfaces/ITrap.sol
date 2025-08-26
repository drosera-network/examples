// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITrap
 * @notice Interface for Drosera Traps
 * @dev This is a minimal interface for the MEV detection traps
 */
interface ITrap {
    /**
     * @notice Collect data for analysis
     * @return Data collected from the current state
     */
    function collect() external view returns (bytes memory);
    
    /**
     * @notice Determine if the trap should respond based on collected data
     * @param data Array of collected data from previous blocks
     * @return shouldTrigger Whether the trap should trigger a response
     * @return responseData Data to pass to the response contract
     */
    function shouldRespond(bytes[] calldata data) external pure returns (bool shouldTrigger, bytes memory responseData);
}
