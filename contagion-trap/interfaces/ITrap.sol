// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITrap {
    /// @notice Collects state data to analyze later.
    function collect() external view returns (bytes memory);

    /// @notice Decides whether a trap should respond, based on collected data.
    /// @param data Collected snapshots (data[0] is newest).
    /// @return shouldTrigger Whether the trap should trigger.
    /// @return responseData Optional data for responder actions.
    function shouldRespond(bytes[] calldata data)
        external
        pure
        returns (bool shouldTrigger, bytes memory responseData);
}
