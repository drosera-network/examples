// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenSupplyTrap} from "../src/TokenSupplyTrap.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @dev forge test --match-contract TokenSupplyTrapTest -vv
contract TokenSupplyTrapTest is Test {
    MockERC20 public mockToken;
    address public user;

    function setUp() public {
        mockToken = new MockERC20(1000 * 10 ** 18);
        user = address(0x123);
    }

    function test_TokenSupplyTrap() external {
        TokenSupplyTrap.CustomCollectStruct[]
            memory data = new TokenSupplyTrap.CustomCollectStruct[](2);
        TokenSupplyTrap tokenSupplyTrap = new TokenSupplyTrap(
            address(mockToken)
        );

        data[0] = tokenSupplyTrap.collect();
        data[1] = tokenSupplyTrap.collect();
        // 10% threshold
        bool isValid = tokenSupplyTrap.isValid(data, 10);
        assert(isValid);
        mockToken.mint(user, 200 * 10 ** 18);

        TokenSupplyTrap.CustomCollectStruct[]
            memory newData = new TokenSupplyTrap.CustomCollectStruct[](
                data.length + 1
            );
        for (uint i = 0; i < data.length; i++) {
            newData[i] = data[i];
        }
        newData[data.length] = tokenSupplyTrap.collect();
        isValid = tokenSupplyTrap.isValid(newData, 10);

        assert(!isValid);
    }
}
