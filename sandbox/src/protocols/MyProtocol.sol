// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {MockBridge} from "./MockBridge.sol";

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

contract MyProtocol {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal tokens;
    EnumerableSet.AddressSet internal bridges;

    address public owner;
    address public trapConfig;

    modifier onlyOwnerOrTrapConfig() {
        require(msg.sender == owner || msg.sender == address(trapConfig), "MyProtocol: not owner or trap");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "MyProtocol: not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        trapConfig = address(0);
    }

    function addToken(address token) public onlyOwner {
        tokens.add(token);
    }

    function removeToken(address token) public onlyOwnerOrTrapConfig {
        tokens.remove(token);
    }

    function addBridge(address bridge) public onlyOwner {
        bridges.add(bridge);
    }

    function removeBridge(address bridge) public onlyOwnerOrTrapConfig {
        bridges.remove(bridge);
    }

    function setTrapConfig(address _trapConfig) public onlyOwner {
        trapConfig = _trapConfig;
    }

    function getTokens() public view returns (address[] memory) {
        return tokens.values();
    }

    function getBridges() public view returns (address[] memory) {
        return bridges.values();
    }
}
