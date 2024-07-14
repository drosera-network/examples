// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "forge-std/console.sol";

contract MockERC20Test is Test {
    MockERC20 public token;
    address public minter;
    address public user;

    function setUp() public {
        minter = address(this);
        user = address(0x123);
        token = new MockERC20(minter);
    }

    function testMinterRole() public view {
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        token.mint(user, mintAmount);
        assertEq(token.balanceOf(user), mintAmount);
    }

    function testMintFailWithoutRole() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        vm.prank(user);
        vm.expectRevert("MockERC20: must have minter role to mint");
        token.mint(user, mintAmount);
    }

    function testMinterAddresses() public view {
        address[] memory minterAddresses = token.getRoleAddresses(token.MINTER_ROLE());
        assertEq(minterAddresses.length, 1);
        assertEq(minterAddresses[0], minter);
    }
}
