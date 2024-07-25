// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITrap {
    function collect() external view returns (bytes memory);
    function isValid(bytes[] calldata data) external view returns (bool, bytes memory);
}
