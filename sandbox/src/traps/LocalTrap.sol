// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MyProtocol} from "../protocols/MyProtocol.sol";
import {MockBridge} from "../protocols/MockBridge.sol";
import {ITrap} from "drosera-lib/interfaces/ITrap.sol";

contract LocalTrap is ITrap {
    struct CustomCollectStruct {
        address[] tokens;
        address[] bridges;
        bool[] mintBurnIssue;
        uint256 blockNumber;
    }

    MyProtocol public myProtocol;
    MockBridge public mockBridge;

    // NOTE: constructor is just used for testing purposes
    constructor(address _myProtocol, address _mockBridge) {
        // These addresses would be known ahead of time in a real scenario or in fork testing and would be defined above
        myProtocol = MyProtocol(_myProtocol);
        mockBridge = MockBridge(_mockBridge);
    }

    function collect() external view returns (bytes memory) {
        address[] memory tokens = myProtocol.getTokens();
        address[] memory bridges = myProtocol.getBridges();
        bool[] memory mintBurnIssue = new bool[](bridges.length);

        // loop through each bridges
        for (uint256 j = 0; j < bridges.length; j++) {
            uint256 lockedAmounts = 0;
            for (uint256 k = 0; k < tokens.length; k++) {
                // check the token balance of the bridge
                uint256 lockedAmount = IERC20(tokens[k]).balanceOf(
                    address(bridges[j])
                );
                lockedAmounts += lockedAmount;
            }

            // get the minted amount of the bridge
            uint256 mintedAmount = IERC20(MockBridge(bridges[j]).receiptToken())
                .totalSupply();

            if (mintedAmount != lockedAmounts) {
                mintBurnIssue[j] = true;
            }
        }

        return
            abi.encode(CustomCollectStruct({
                tokens: tokens,
                bridges: bridges,
                mintBurnIssue: mintBurnIssue,
                blockNumber: block.number
            }));
    }

    function isValid(
        bytes[] calldata dataPoints
    ) external pure returns (bool, bytes memory) {
        uint256 len = dataPoints.length;

        // loop through each block
        for (uint256 i = 0; i < len; i++) {
            // loop through each bridge
            CustomCollectStruct memory data = abi.decode(
                dataPoints[i],
                (CustomCollectStruct)
            );
            for (uint256 j = 0; j < data.bridges.length; j++) {
                if (data.mintBurnIssue[j]) {
                    return (false, bytes(""));
                }
            }
        }

        return (true, bytes(""));
    }
}
