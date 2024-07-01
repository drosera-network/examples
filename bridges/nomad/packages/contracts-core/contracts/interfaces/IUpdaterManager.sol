// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.0 <=0.8.12;

interface IUpdaterManager {
    function slashUpdater(address payable _reporter) external;

    function updater() external view returns (address);
}
