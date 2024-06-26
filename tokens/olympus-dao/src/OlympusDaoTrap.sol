// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces/IBondFixedExpiryTellerWithDrosera.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "forge-std/Test.sol";

// Drosera Trap Contract
// Purpose: This contract defines validation logic that determines an invalid state.
contract OlympusDaoTrap is Test {
    // State Variables
    // - Number of blocks between points
    uint public blockInterval = 5;
    address constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
    address constant treasuryAddress =
        0x007FE7c498A2Cf30971ad8f2cbC36bd14Ac51156;
    address public protocol;
    address public account;

    // NOTE: constructor args are used here only for testing purposes
    // - In production, the contract will be deployed with the correct protocol and account
    constructor(address _protocol, address _account) {
        protocol = _protocol;
        account = _account;
    }

    // Core Functions
    function collect() external view returns (uint[] memory) {
        uint treasury = ERC20(protocol).balanceOf(account);
        uint[] memory result = new uint[](1);
        result[0] = treasury;
        return result;
    }

    function isValid(
        uint[][] calldata dataPoints
    ) external pure returns (bool) {
        uint currentX = dataPoints[0][0];
        uint previousX = dataPoints[1][0];
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
