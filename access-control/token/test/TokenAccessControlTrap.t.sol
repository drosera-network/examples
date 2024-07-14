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

    function setUp() public {
        mockToken = new MockERC20(address(this));
        user = address(0x123);
    }

    function test_TokenAccessControlTrap() external {
        TokenAccessControlTrap.CustomCollectStruct[]
            memory data = new TokenAccessControlTrap.CustomCollectStruct[](1);
        address tokenAccessControlTrap = address(
            new TokenAccessControlTrap(address(mockToken))
        );

        data[0] = TokenAccessControlTrap(tokenAccessControlTrap).collect();
        bool isValid = TokenAccessControlTrap(tokenAccessControlTrap).isValid(
            data
        );
        assert(isValid);

        // Perform exploit 
        vm.prank(user);
        mockToken.grantMinter(user);

        TokenAccessControlTrap.CustomCollectStruct[]
            memory newData = new TokenAccessControlTrap.CustomCollectStruct[](
                data.length + 1
            );
        for (uint i = 0; i < data.length; i++) {
            newData[i] = data[i];
        }
        newData[data.length] = TokenAccessControlTrap(tokenAccessControlTrap)
            .collect();
        isValid = TokenAccessControlTrap(tokenAccessControlTrap).isValid(
            newData
        );
        // Minter list changed, so it should be invalid.
        assert(!isValid);
    }
}
