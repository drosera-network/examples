// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AaveFlashLoanTrap.sol";

contract AaveLikeProtocol {
    uint256 public availableLiquidityValue;
    bool public paused;
    address public owner;
   

    constructor(address _owner) {
        owner = _owner;
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyTrapContract() {
        require(msg.sender == address(trapContract), "Not authorized");
        _;
    }

    AaveFlashLoanTrap public trapContract;

    function setTrapContract(AaveFlashLoanTrap _trapContract) external {
        trapContract = _trapContract;
    }

    function setLiquidity(uint256 _liquidity) external onlyOwner {
        availableLiquidityValue = _liquidity;
    }

    function availableLiquidity() external view returns (uint256) {
        return availableLiquidityValue;
    }

    function pause() external onlyTrapContract {
        paused = true;
    }

    function unpause() external onlyTrapContract {
        paused = false;
    }
}
