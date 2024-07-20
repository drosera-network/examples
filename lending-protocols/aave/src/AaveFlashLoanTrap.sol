// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/console.sol";

interface IAaveLikeProtocol {
    function availableLiquidity() external view returns (uint256);
    function pause() external;
}

contract  AaveFlashLoanTrap {
    struct LiquidityInfo {
        uint256 availableLiquidity;
    }

    IAaveLikeProtocol public protocol;
    address public owner;

    constructor(address _protocol) {
        protocol = IAaveLikeProtocol(_protocol);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }


    function collect() external view returns (LiquidityInfo memory) {
        uint256 availableLiquidity = protocol.availableLiquidity();
        return LiquidityInfo({availableLiquidity: availableLiquidity});
    }

    function isValid(LiquidityInfo[] calldata dataPoints) external onlyOwner returns (bool) {
        if (dataPoints.length < 2) {
            return true;
        }

        uint256 liquidityDecrease = dataPoints[0].availableLiquidity - dataPoints[1].availableLiquidity;
        uint256 decreasePercentage = (liquidityDecrease * 100) / dataPoints[0].availableLiquidity;
        console.log("decreasePercentage: ",decreasePercentage);
        if (decreasePercentage > 10) {
            protocol.pause();
            return false;
        }
        return true;
    }
}
