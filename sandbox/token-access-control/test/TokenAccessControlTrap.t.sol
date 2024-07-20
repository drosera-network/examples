// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenAccessControlTrap} from "../src/TokenAccessControlTrap.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @dev forge test --match-contract LocalTrapTest -vv
contract TokenAccessControlTrapTest is Test {
    MockERC20 public mockToken;
    // Trap Config lives on chain while the Trap itself lives off chain
    address public trapConfig = address(0xDEADBEEF);
    address public user;
    address public anotherUser;

    function setUp() public {
        mockToken = new MockERC20();
        user = address(0x123);
        anotherUser = address(0x456);
    }

    function test_TokenAccessControlTrap() external {
        TokenAccessControlTrap.CustomCollectStruct[]
            memory data = new TokenAccessControlTrap.CustomCollectStruct[](2);
        address tokenAccessControlTrap = address(
            new TokenAccessControlTrap(address(mockToken))
        );

        data[0] = TokenAccessControlTrap(tokenAccessControlTrap).collect();
        data[1] = data[0];
        bool isValid = TokenAccessControlTrap(tokenAccessControlTrap).isValid(
            data
        );
        assert(isValid);

        // Perform exploit, add unknown minter
        vm.prank(user);
        mockToken.grantMinter(user);

        TokenAccessControlTrap.CustomCollectStruct[]
            memory newData = new TokenAccessControlTrap.CustomCollectStruct[](
                2
            );

        newData[0] = data[0];
        newData[1] = TokenAccessControlTrap(tokenAccessControlTrap).collect();
        isValid = TokenAccessControlTrap(tokenAccessControlTrap).isValid(
            newData
        );

        // Reset and add another minter
        vm.prank(address(this));
        mockToken.revokeRole(mockToken.MINTER_ROLE(), user);

        vm.prank(anotherUser);
        mockToken.grantMinter(anotherUser);

        TokenAccessControlTrap.CustomCollectStruct[]
            memory sameLengthDifferentContent = new TokenAccessControlTrap.CustomCollectStruct[](
                2
            );
        sameLengthDifferentContent[0] = newData[1];
        sameLengthDifferentContent[1] = TokenAccessControlTrap(
            tokenAccessControlTrap
        ).collect();

        isValid = TokenAccessControlTrap(tokenAccessControlTrap).isValid(
            sameLengthDifferentContent
        );

        assert(!isValid);
    }
}
