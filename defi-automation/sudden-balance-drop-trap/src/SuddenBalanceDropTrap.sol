// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ITrap} from "contracts/interfaces/ITrap.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
}

/**
 * @title SuddenBalanceDropTrap
 * @notice Monitor vault balances for sudden drops
 * @dev Simple trap that detects large balance drops between blocks
 */
contract SuddenBalanceDropTrap is ITrap {
    uint256 constant MAX_DROP_BPS = 1000; // 10% drop threshold
    uint256 constant MIN_BALANCE = 50000e6; // $50k minimum balance to monitor

    struct VaultInfo {
        address vault;
        address token;
    }

    struct VaultBalance {
        address vault;
        address token;
        uint256 balance;
        uint256 blockNumber;
    }

    struct BalanceDrop {
        address vault;
        address token;
        uint256 oldBalance;
        uint256 newBalance;
        uint256 dropBps;
    }

    VaultInfo[] public monitoredVaults;

    constructor() {
        // Monitor real treasury/vault addresses with major stablecoins
        monitoredVaults.push(
            VaultInfo({
                vault: 0x742d35cC6634C0532925a3B8d80a6B24C5D06e41,
                token: 0xa0B86a33e6441fD9Eec086d4E61ef0b5D31a5e7D
            })
        );
    }

    function collect() external view override returns (bytes memory) {
        VaultBalance[] memory balances = new VaultBalance[](
            monitoredVaults.length
        );

        for (uint256 i = 0; i < monitoredVaults.length; i++) {
            VaultInfo memory info = monitoredVaults[i];

            uint256 balance = 0;
            try IERC20(info.token).balanceOf(info.vault) returns (
                uint256 _balance
            ) {
                balance = _balance;
            } catch {}

            balances[i] = VaultBalance({
                vault: info.vault,
                token: info.token,
                balance: balance,
                blockNumber: block.number
            });
        }

        return abi.encode(balances);
    }

    function shouldRespond(
        bytes[] calldata data
    )
        external
        pure
        override
        returns (bool shouldTrigger, bytes memory responseData)
    {
        if (data.length < 2) {
            return (false, "");
        }

        VaultBalance[] memory current = abi.decode(data[0], (VaultBalance[]));
        VaultBalance[] memory previous = abi.decode(data[1], (VaultBalance[]));

        if (current.length != previous.length) {
            return (false, "");
        }

        BalanceDrop[] memory drops = new BalanceDrop[](current.length);
        uint256 dropCount = 0;

        for (uint256 i = 0; i < current.length; i++) {
            if (
                current[i].vault != previous[i].vault ||
                current[i].token != previous[i].token
            ) {
                continue;
            }

            uint256 oldBalance = previous[i].balance;
            uint256 newBalance = current[i].balance;

            // Only check if old balance is above minimum threshold
            if (oldBalance < MIN_BALANCE) {
                continue;
            }

            // Check for balance drop
            if (newBalance < oldBalance) {
                uint256 drop = oldBalance - newBalance;
                uint256 dropBps = (drop * 10000) / oldBalance;

                if (dropBps >= MAX_DROP_BPS) {
                    drops[dropCount++] = BalanceDrop({
                        vault: current[i].vault,
                        token: current[i].token,
                        oldBalance: oldBalance,
                        newBalance: newBalance,
                        dropBps: dropBps
                    });
                }
            }
        }

        if (dropCount > 0) {
            // Return the first drop's data in the format expected by response_function:
            // handleBalanceDrop(address,uint256,uint256)
            BalanceDrop memory firstDrop = drops[0];
            return (
                true,
                abi.encode(
                    firstDrop.vault, // vault address
                    firstDrop.oldBalance, // old balance
                    firstDrop.newBalance // new balance
                )
            );
        }

        return (false, "");
    }

    // NOTE: For testing purposes only
    function getMonitoredVaults() external view returns (VaultInfo[] memory) {
        return monitoredVaults;
    }

    // NOTE: For testing purposes only
    function addMonitoredVault(address vault, address token) external {
        monitoredVaults.push(VaultInfo({vault: vault, token: token}));
    }

    // NOTE: For testing purposes only
    function getDropThreshold() external pure returns (uint256) {
        return MAX_DROP_BPS;
    }
}
