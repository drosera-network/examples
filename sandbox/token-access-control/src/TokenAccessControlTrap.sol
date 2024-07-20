// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {MockERC20} from "./MockERC20.sol";
import {console} from "forge-std/console.sol";

contract TokenAccessControlTrap {
    MockERC20 public mockToken;

    struct CustomCollectStruct {
        address[] minterAddresses;
    }

    constructor(address _mockToken) {
        mockToken = MockERC20(_mockToken);
    }

    function collect() external view returns (CustomCollectStruct memory) {
        address[] memory minterAddresses = mockToken.getRoleAddresses(
            mockToken.MINTER_ROLE()
        );
        return CustomCollectStruct({minterAddresses: minterAddresses});
    }

    function isValid(
        CustomCollectStruct[] calldata dataPoints
    ) external pure returns (bool) {
        if (dataPoints.length < 2) {
            revert("DataPoints length should be at least 2");
        }

        for (uint256 i = 1; i < dataPoints.length; i++) {
            address[] memory oldList = dataPoints[i - 1].minterAddresses;
            address[] memory newList = dataPoints[i].minterAddresses;

            console.log("oldListLength: ", oldList.length);
            console.log("newListLength: ", newList.length);

            if (oldList.length != newList.length) {
                console.log("Address length mismatch detected!");
                return false;
            }

            bool[] memory found = new bool[](oldList.length);

            for (uint256 j = 0; j < oldList.length; j++) {
                bool matchFound = false;
                for (uint256 k = 0; k < newList.length; k++) {
                    if (oldList[j] == newList[k] && !found[k]) {
                        found[k] = true;
                        matchFound = true;
                        break;
                    }
                }
                if (!matchFound) {
                    console.log("Address mismatch detected!");
                    return false;
                }
            }
        }
        console.log("No change.");
        return true;
    }
}
