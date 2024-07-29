// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ITrap} from "drosera-lib/interfaces/ITrap.sol";

// https://github.com/prisma-fi/prisma-contracts/blob/main/contracts/interfaces/ITroveManager.sol
interface ITroveManager {
    function Troves(
        address
    )
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 stake,
            uint8 status,
            uint128 arrayIndex,
            uint256 activeInterestIndex
        );
}

contract PrismaTroveTrap is ITrap {
    struct CollectOutput {
        uint256 debt;
        uint256 coll;
        uint256 collBalance;
    }

    ITroveManager troveManager =
        ITroveManager(0x1CC79f3F47BfC060b6F761FcD1afC6D399a968B6);

    // Exploited user's address
    address public constant troveOwner =
        0x56A201b872B50bBdEe0021ed4D1bb36359D291ED;

    // The targeted collateral token
    IERC20 wstETH = IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function collect() external view returns (bytes memory) {
        uint256 debt;
        uint256 coll;

        // Collect the user's trove data
        (debt, coll, , , , ) = troveManager.Troves(troveOwner);

        // Collect the user's collateral balance
        uint256 collBalance = wstETH.balanceOf(troveOwner);

        return
            abi.encode(CollectOutput({debt: debt, coll: coll, collBalance: collBalance}));
    }

    function isValid(
        bytes[] calldata dataPoints
    ) external pure returns (bool, bytes memory) {
        CollectOutput memory currentBlock = abi.decode(dataPoints[0], (CollectOutput));
        CollectOutput memory previousBlock = abi.decode(dataPoints[1], (CollectOutput));

        // Check for user collateral decrease
        if (currentBlock.coll < previousBlock.coll) {
            uint256 collDiff = previousBlock.coll - currentBlock.coll;

            // Check if the collateral has decreased by more than 10% from the previous block
            if (collDiff > (previousBlock.coll / 10)) {
                // Check if the user's collateral balance has increased from redemption
                if (
                    currentBlock.collBalance <
                    previousBlock.collBalance + collDiff
                ) {
                    // Check if the user's debt is 0 from a liquidation event
                    if (currentBlock.debt != 0) {
                        // The user's collateral has decreased by more than 10% from the previous block, they did not redeem any collateral, and they have debt still.
                        // Exploit occured! Trigger the emergency response.
                        return (false, bytes(""));
                    }
                }
            }
        }
        return (true, bytes(""));
    }
}
