// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {LocalTrap} from "../src/traps/LocalTrap.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {MyProtocol} from "../src/protocols/MyProtocol.sol";
import {MockBridge} from "../src/protocols/MockBridge.sol";

/// @dev forge test --match-contract LocalTrapTest -vv
contract LocalTrapTest is Test {
    MockBridge public mockBridge;
    MyProtocol public myProtocol;
    ERC20Mock public token;

    // Trap Config lives on chain while the Trap itself lives off chain
    address public trapConfig = address(0xDEADBEEF);

    function setUp() public {
        mockBridge = new MockBridge();
        myProtocol = new MyProtocol();
        token = new ERC20Mock();
        token.mint(address(this), 100 ether);

        myProtocol.addBridge(address(mockBridge));
        myProtocol.addToken(address(token));
        myProtocol.addToken(address(mockBridge.receiptToken()));
        myProtocol.setTrapConfig(trapConfig);
    }

    function test_LocalTrap() external {
        // Trap is ran on current block
        bytes[] memory data = new bytes[](1);
        address localTrap = address(new LocalTrap(address(myProtocol), address(mockBridge)));
        data[0] = LocalTrap(localTrap).collect();
        (bool shouldRespond,) = LocalTrap(localTrap).shouldRespond(data);

        // No exploit seen
        assert(!shouldRespond);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 12);

        // Perform exploit
        ERC20Mock(mockBridge.receiptToken()).mint(address(this), 10 ether);

        // Trap is ran next block
        data = new bytes[](1);
        localTrap = address(new LocalTrap(address(myProtocol), address(mockBridge)));
        data[0] = LocalTrap(localTrap).collect();
        (shouldRespond,) = LocalTrap(localTrap).shouldRespond(data);

        // Exploit seen
        assert(shouldRespond);

        // Remove bridge
        vm.prank(trapConfig);
        myProtocol.removeBridge(address(mockBridge));
        assert(myProtocol.getBridges().length == 0);
    }
}
