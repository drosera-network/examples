// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

// This trap detects sudden drops in the ETH balance of a specific wallet.
contract BalanceDropTrap is ITrap {
    // The wallet address to monitor (Example: Vitalik Buterin's address)
    address constant TARGET_WALLET = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    
    // Using BPS for finer control (10,000 = 100%)
    uint256 constant BPS = 10_000;
    uint256 constant THRESHOLD_BPS = 5_000; // 50% threshold

    // This function runs on every block and records the wallet's current ETH balance.
    function collect() external view override returns (bytes memory) {
        // Including block.number for easier debugging as suggested
        return abi.encode(block.number, TARGET_WALLET.balance);
    }

    // This function analyzes the data from past blocks.
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // At least 2 blocks of data are needed for analysis.
        if (data.length < 2) {
            return (false, bytes(""));
        }

        // Drosera passes samples newest first: data[0] is current, data[1] is previous.
        ( , uint256 currentBalance) = abi.decode(data[0], (uint256, uint256));
        ( , uint256 previousBalance) = abi.decode(data[1], (uint256, uint256));
        
        // If the balance has not dropped or the previous balance was 0, there is no issue.
        if (currentBalance >= previousBalance || previousBalance == 0) {
            return (false, bytes(""));
        }

        // Calculate the drop amount and percentage in BPS.
        uint256 dropBps = ((previousBalance - currentBalance) * BPS) / previousBalance;

        // If the drop is greater than our threshold, TRIGGER THE ALARM!
        if (dropBps >= THRESHOLD_BPS) {
            return (true, abi.encode(previousBalance, currentBalance));
        }

        // If the drop is less than the threshold, there is no issue.
        return (false, bytes(""));
    }
}
