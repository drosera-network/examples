// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EventLogger {
    address public owner;
    uint256 public eventCount;

    event Sighting(uint256 indexed eventId, string message, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    function recordSighting(string memory message) external {
        eventCount++;
        emit Sighting(eventCount, message, block.timestamp);
    }
}
