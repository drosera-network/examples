// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IUniPool {
    function liquidity() external view returns (uint256);
}

interface ISynapseBridge {
    function paused() external view returns (bool);
}

contract ForkTrap {
    struct CustomCollectStruct {
        bool isBridgePaused;
        uint256 uniAmount;
        uint256 poolAmount;
        uint256 blockNumber;
    }

    function collect() external view returns (CustomCollectStruct memory) {
        bool paused = this.isBridgePaused();
        uint256 uniAmount = this.getSomeUniData();
        uint256 poolAmount = this.getSomeUniPoolData();

        return
            CustomCollectStruct({
                isBridgePaused: paused,
                uniAmount: uniAmount,
                poolAmount: poolAmount,
                blockNumber: block.number
            });
    }

    function isValid(
        CustomCollectStruct[] calldata dataPoints
    ) external pure returns (bool) {
        uint256 len = dataPoints.length;

        if (len == 2) {
            if (
                !dataPoints[0].isBridgePaused &&
                dataPoints[0].uniAmount > dataPoints[1].uniAmount
            ) {
                return false;
            }
        }

        return true;
    }

    function getSomeUniData() public view returns (uint256) {
        address uniToken = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        uint256 uniAmount = IERC20(uniToken).balanceOf(uniToken);
        return uniAmount;
    }

    function getSomeUniPoolData() public view returns (uint256) {
        address usdcWETHPool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
        uint256 poolAmount = IUniPool(usdcWETHPool).liquidity();
        return poolAmount;
    }

    function isBridgePaused() public view returns (bool) {
        address synapseBridge = 0x2796317b0fF8538F253012862c06787Adfb8cEb6;
        return ISynapseBridge(synapseBridge).paused();
    }
}
