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
        address[] memory minterAddresses = mockToken.getRoleAddresses(mockToken.MINTER_ROLE());
        return CustomCollectStruct({minterAddresses: minterAddresses});
    }

    function isValid(
        CustomCollectStruct[] calldata dataPoints
    ) external pure returns (bool) {
        if (dataPoints.length == 0) {
            revert("DataPoints length should be greater than 0");
        }

        if (dataPoints.length == 1) {
            return true;
        }

        address[] memory oldList = dataPoints[0].minterAddresses;
        address[] memory newList = dataPoints[1].minterAddresses;
        // all minter addresses should be same at each block.
        if (oldList.length != newList.length) {
            return false;
        }

        bool[] memory found = new bool[](oldList.length);

        for (uint256 i = 0; i < oldList.length; i++) {
            bool matchFound = false;
            for (uint256 j = 0; j < newList.length; j++) {
                if (oldList[i] == newList[j] && !found[j]) {
                    found[j] = true;
                    matchFound = true;
                    break;
                }
            }
            if (!matchFound) {
                return false;
            }
        }

        return true;
    }
}
