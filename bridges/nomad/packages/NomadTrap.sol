// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITrap} from "drosera-lib/interfaces/ITrap.sol";

// Drosera Trap Contract
// Purpose: This contract defines validation logic that determines an invalid state.
contract NomadTrap is ITrap {
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
    function collect() external view returns (bytes memory) {
        uint256 treasury = IERC20(protocol).balanceOf(account);
        uint256[] memory result = new uint[](1);
        result[0] = treasury;
        return abi.encode(result);
    }

    function isValid(
        bytes[] calldata dataPoints
    ) external pure returns (bool, bytes memory) {
        uint256[] memory currentX = abi.decode(dataPoints[0], (uint256[]));
        uint256[] memory previousX = abi.decode(dataPoints[1], (uint256[]));

        if (previousX[0] > currentX[0]) {
            // Negative difference or no change
            if ((100 * (previousX[0] - currentX[0])) / previousX[0] <= 30) {
                return (true, bytes(""));
            }
        }

        return (false, bytes(""));
    }

    // Utility Functions
}
