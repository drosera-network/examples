// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MockBridge {
    address public receiptToken;

    constructor() {
        receiptToken = address(new ERC20Mock());
    }

    // user => token => amount
    mapping(address => mapping(address => uint256)) public locked;

    function bridge(address token, uint256 amount, address to) external {
        ERC20Mock(token).transferFrom(msg.sender, address(this), amount);

        locked[msg.sender][token] += amount;

        ERC20Mock(receiptToken).mint(to, amount);
    }

    function redeem(address token, uint256 amount) external {
        require(
            locked[msg.sender][token] >= amount,
            "MockBridge: insufficient balance"
        );

        require(
            ERC20Mock(receiptToken).balanceOf(address(this)) >= amount,
            "MockBridge: insufficient balance"
        );

        ERC20Mock(receiptToken).burn(msg.sender, amount);

        locked[msg.sender][token] -= amount;

        ERC20Mock(token).transfer(msg.sender, amount);
    }
}
