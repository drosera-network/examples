// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/interfaces/ITrap.sol";

contract BlockTimeTrap is ITrap {
    struct CollectOutput {
        uint256 blockTimestamp;
    }

    function collect() external view returns (bytes memory) {
        return abi.encode(CollectOutput({blockTimestamp: block.timestamp}));
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, bytes(""));
        }

        CollectOutput memory recent = abi.decode(data[0], (CollectOutput));
        CollectOutput memory older = abi.decode(data[1], (CollectOutput));

        uint256 timeDifference = recent.blockTimestamp - older.blockTimestamp;

        // Trigger if the time between blocks is unusually long (e.g., > 30 seconds)
        if (timeDifference > 30) {
            return (true, abi.encode("High latency detected between blocks!"));
        }

        return (false, bytes(""));
    }
}
