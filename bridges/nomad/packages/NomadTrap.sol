// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";

// Drosera Trap Contract
// Purpose: This contract defines validation logic that determines an invalid state.
contract NomadTrap is Test {
    // State Variables
    // - Number of blocks between points
    uint256 public blockInterval = 5;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant treasuryAddress =
        0x5D94309E5a0090b165FA4181519701637B6DAEBA;
    address public protocol;
    address public account;

    // NOTE: constructor args are used here only for testing purposes
    // - In production, the contract will be deployed with the correct protocol and account
    constructor(address _protocol, address _account) {
        // The owner is set to the msg.sender (i.e., the address deploying the contract)
        // by the Ownable constructor automatically.
        protocol = _protocol;
        account = _account;
    }

    // Core Functions
    function collect() external view returns (uint256[] memory) {
        uint256 treasury = IERC20(protocol).balanceOf(account);
        uint256[] memory result = new uint[](1);
        result[0] = treasury;
        return result;
    }

    function isValid(
        uint256[][] calldata dataPoints
    ) external pure returns (bool) {
        uint256 currentX = dataPoints[0][0];
        uint256 previousX = dataPoints[1][0];
        if (previousX > currentX) {
            // Negative difference or no change
            if ((100 * (previousX - currentX)) / previousX <= 30) {
                return true;
            }
        }

        return false;
    }

    // Utility Functions
}
