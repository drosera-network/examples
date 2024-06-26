// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.0 <=0.8.12;

interface IMessageRecipient {
    function handle(uint32 _origin, uint32 _nonce, bytes32 _sender, bytes memory _message)
        external;
}
