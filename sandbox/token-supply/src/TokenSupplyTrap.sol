// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {MockERC20} from "./MockERC20.sol";
import {console} from "forge-std/console.sol";

contract TokenSupplyTrap {
    MockERC20 public mockToken;

    struct CustomCollectStruct {
        uint256 totalSupply;
    }

    constructor(address _mockToken) {
        mockToken = MockERC20(_mockToken);
    }

    function collect() external view returns (CustomCollectStruct memory) {
        uint256 totalSupply = mockToken.totalSupply();
        return CustomCollectStruct({totalSupply: totalSupply});
    }

    function isValid(
        CustomCollectStruct[] calldata dataPoints,
        uint16 allowedIncreasePercentage
    ) external pure returns (bool) {
        if (dataPoints.length == 0) {
            revert("DataPoints length should be greater than 0");
        }

        for (uint256 i = 1; i < dataPoints.length; i++) {
            uint256 previousSupply = dataPoints[i - 1].totalSupply;
            uint256 currentSupply = dataPoints[i].totalSupply;
            uint256 threshold = previousSupply +
                ((previousSupply * allowedIncreasePercentage) / 100);

            if (currentSupply > threshold) {
                return false;
            }
        }
        return true;
    }
}
