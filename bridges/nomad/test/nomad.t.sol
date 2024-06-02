// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ReplicaWithDrosera} from "../packages/contracts-core/contracts/ReplicaWithDrosera.sol";
import {NomadTrap} from "../packages/NomadTrap.sol";

interface IDroseraTrap {
    function collect() external view returns (uint256[] memory);

    function isValid(
        uint256[][] calldata dataPoints
    ) external view returns (bool);
}

/// @title Nomad Attacker Tests
/// @notice Purpose: Run the nomad exploit and test Drosera's emergency response
/// @dev forge test -vv
contract NomadAttacker is Test {
    /* ========== STATE VARIABLES ========== */
    bytes _message;
    uint256 newFork;
    uint256 previousFork;
    bytes32 public trapHash;
    IDroseraTrap newTrapContract;
    IDroseraTrap previousTrapContract;
    string public TrapByteCodePath = "NomadTrap.sol:NomadTrap";
    string public protocolByteCodePath =
        "ReplicaWithDrosera.sol:ReplicaWithDrosera";
    IReplica constant Replica =
        IReplica(0x5D94309E5a0090b165FA4181519701637B6DAEBA);
    IERC20 constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    function setUp() public {
        /* ---- CREATE FORK AT PRE-EXPLOIT BLOCK ---- */
        previousFork = vm.createSelectFork("mainnet", 15_259_100);
        previousTrapContract = IDroseraTrap(_testDeployTrapContract());

        /* ---- CREATE FORK AT POST-EXPLOIT BLOCK ---- */
        newFork = vm.createSelectFork("mainnet", 15_259_101);
        newTrapContract = IDroseraTrap(_testDeployTrapContract());

        console.log(
            "\nNomad Exploit Mechanism: Attackers can copy the original user's transaction calldata and replacing the receive address with a personal one."
        );
    }

    function _testDeployTrapContract() public returns (address) {
        // Deploy the trap contract
        bytes memory args = abi.encode(
            WBTC,
            0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3
        );
        bytes memory byteCode = abi.encodePacked(
            vm.getCode(TrapByteCodePath),
            args
        );
        address deployed;
        assembly {
            deployed := create(0, add(byteCode, 0x20), mload(byteCode))
        }
        IDroseraTrap trapContract = IDroseraTrap(deployed);

        return address(trapContract);
    }

    function testExploit() external {
        // Start at pre-exploit block
        vm.selectFork(previousFork);
        uint256 startingBlock = block.number;
        console.log(
            "\n---------- Start from Block %s ----------\n",
            startingBlock
        );

        // Log pre-exploit bridge WBTC balance
        emit log_named_decimal_uint(
            "Bridge WBTC Balance",
            IERC20(WBTC).balanceOf(
                address(0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3)
            ),
            8
        );

        // First Collect
        console.log("DROSERA Collected Data From Block %s", block.number);
        uint256[] memory initialCollectedData = previousTrapContract.collect();
        require(initialCollectedData.length > 0, "Collected data is empty");

        // Move the VM up 1 block by switching to post-exploit fork
        vm.selectFork(newFork);
        console.log("\n---------- Warp to Block %s ----------\n", block.number);
        uint256 endingBlock = block.number;
        console.log("Attackers perform multiple exploits");

        // Log post-exploit bridge WBTC balance
        emit log_named_decimal_uint(
            "Bridge WBTC Balance",
            IERC20(WBTC).balanceOf(
                address(0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3)
            ),
            8
        );

        // Second Collect
        console.log("DROSERA Collected Data From Block %s", block.number);
        uint256[] memory finalCollectedData = newTrapContract.collect();
        require(finalCollectedData.length > 0, "Collected data is empty");

        // Check the trap
        console.log(
            "DROSERA performs trap logic on %s and %s",
            startingBlock,
            endingBlock
        );
        uint256[][] memory dataPoints = new uint[][](2);
        dataPoints[0] = finalCollectedData;
        dataPoints[1] = initialCollectedData;
        bool result = newTrapContract.isValid(dataPoints);
        require(result == false, "Trap should be invalid");
        console.log(
            "DROSERA identified that state is invalid and emergency response is required"
        );

        // Update code of nomad replica contract to be integrated with Drosera
        bytes memory code = vm.getDeployedCode(protocolByteCodePath);
        vm.etch(address(Replica), code);

        /* ---- USER 0 SUBMITS CLAIM ---- */
        console.log("DROSERA submits claim that state is invalid");
        Replica.emergencyPause();

        // Post-Check
        require(Replica.isPaused() == true);

        // Move the VM up 1 blocks
        uint256 numOfBlocks = 1;
        vm.roll(numOfBlocks + block.number);
        skip(numOfBlocks * 12);
        console.log(
            "\n---------- Mine Next Block %s ----------\n",
            block.number
        );

        // Prove Attacker Mitigation
        console.log("An attacker attempts to perform exploit again");
        vm.expectRevert("NomadReplica: contract is paused");
        bool suc = Replica.process(_message);
        assert(!suc);
        console.log(
            "Attacker transaction reverts with NomadReplica: contract is paused"
        );

        // Log post-mitigation bridge WBTC balance
        emit log_named_decimal_uint(
            "Bridge WBTC Balance",
            IERC20(WBTC).balanceOf(
                address(0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3)
            ),
            8
        );

        console.log("Attack mitigated successfully");
        console.log("Drosera saved $42,465,099.89 in WBTC from being siphoned");
    }
}

interface IReplica {
    function process(bytes memory _message) external returns (bool _success);
    function isPaused() external view returns (bool);
    function emergencyPause() external;
}
