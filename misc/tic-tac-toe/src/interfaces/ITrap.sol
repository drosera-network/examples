// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ITrap {
    function collect() external view returns (bytes memory);
    function isValid(bytes[] calldata dataPoints) external pure returns (bool);
}