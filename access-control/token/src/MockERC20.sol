// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address account) ERC20("MyToken", "TKN") {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
        _grantRole(MINTER_ROLE, account);
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MockERC20: must have minter role to mint"
        );
        _mint(to, amount);
    }

    function grantMinter(address account) public {
        // vulnerable implementation
        _grantRole(MINTER_ROLE, account);
    }

    function getRoleAddresses(bytes32 role) public view returns (address[] memory) {
        uint256 count = getRoleMemberCount(role);
        address[] memory addresses = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            addresses[i] = getRoleMember(role, i);
        }
        return addresses;
    }
}
