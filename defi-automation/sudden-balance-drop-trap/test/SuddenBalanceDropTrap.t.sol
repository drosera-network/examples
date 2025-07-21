// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SuddenBalanceDropTrap} from "../src/SuddenBalanceDropTrap.sol";
import {SuddenBalanceDropResponse} from "../src/SuddenBalanceDropResponse.sol";
import {MockVault} from "./mocks/MockVault.sol";

// Simple mock USDC token for testing
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC", 6) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract SuddenBalanceDropTrapTest is Test {
    SuddenBalanceDropTrap public trap;
    SuddenBalanceDropResponse public responseContract;
    MockUSDC public mockUSDC;
    MockVault public mockVault;

    address constant MOCK_TRAP_CONFIG =
        0x7E1b5cA35bd6BcAe8Ff33C0dDf79EffCFf0Ad19e;

    function setUp() public {
        // Deploy contracts first
        mockUSDC = new MockUSDC();
        responseContract = new SuddenBalanceDropResponse(MOCK_TRAP_CONFIG);

        // Deploy mock vault with the target USDC address (will be etched)
        mockVault = new MockVault(
            0xa0B86a33e6441fD9Eec086d4E61ef0b5D31a5e7D,
            address(responseContract)
        );

        // Etch the contracts to the hardcoded addresses in the trap
        vm.etch(
            0xa0B86a33e6441fD9Eec086d4E61ef0b5D31a5e7D,
            address(mockUSDC).code
        );
        vm.etch(
            0x742d35cC6634C0532925a3B8d80a6B24C5D06e41,
            address(mockVault).code
        );

        // Manually set the storage for the etched vault
        // Slot 0: paused (bool) and guardian (address) are packed
        // paused takes 1 byte at position 0, guardian takes 20 bytes after that
        bytes32 packedSlot0 = bytes32(
            uint256(uint160(address(responseContract))) << 8
        );
        vm.store(
            0x742d35cC6634C0532925a3B8d80a6B24C5D06e41,
            bytes32(uint256(0)),
            packedSlot0
        );

        // Slot 1: owner address
        vm.store(
            0x742d35cC6634C0532925a3B8d80a6B24C5D06e41,
            bytes32(uint256(1)),
            bytes32(uint256(uint160(address(this)))) // Set test contract as owner
        );

        // Now deploy the trap which will use the etched addresses
        trap = new SuddenBalanceDropTrap();
    }

    // FILE: drosera.toml
    // [traps.sudden_balance_drop]
    // path = "out/SuddenBalanceDropTrap.sol/SuddenBalanceDropTrap.json"
    // response_contract = "0xresponsecontractaddress0000000000000000"
    // response_function = "handleBalanceDropWithEvent(address,uint256,uint256)"
    // cooldown_period_blocks = 50
    // min_number_of_operators = 1
    // max_number_of_operators = 5
    // block_sample_size = 2
    //
    // forge test --contracts ./test/SuddenBalanceDropTrap.t.sol --match-test test_EventOnlyResponse -vvvv
    function test_EventOnlyResponse() public {
        // Get the monitored vault info
        SuddenBalanceDropTrap.VaultInfo[] memory vaults = trap
            .getMonitoredVaults();
        address vaultAddr = vaults[0].vault;
        address tokenAddr = vaults[0].token;

        // Mint initial balance
        MockUSDC(tokenAddr).mint(vaultAddr, 100000e6);

        // Collect data before drop
        bytes memory data1 = trap.collect();

        // Simulate balance drop
        vm.roll(block.number + 1);
        vm.prank(vaultAddr);
        MockUSDC(tokenAddr).transfer(address(0xdead), 20000e6);

        // Collect data after drop
        bytes memory data2 = trap.collect();

        bytes[] memory dataArray = new bytes[](2);
        dataArray[0] = data2;
        dataArray[1] = data1;

        (bool shouldTrigger, bytes memory responseData) = trap.shouldRespond(
            dataArray
        );
        assertTrue(shouldTrigger);

        // Expect the BalanceDropHandled event to be emitted
        vm.expectEmit(true, false, false, true);
        emit SuddenBalanceDropResponse.BalanceDropHandled(
            vaultAddr,
            100000e6,
            80000e6,
            block.timestamp
        );

        // Call the event-only response
        vm.prank(MOCK_TRAP_CONFIG);
        (bool success, ) = address(responseContract).call(
            abi.encodePacked(
                bytes4(
                    keccak256(
                        "handleBalanceDropWithEvent(address,uint256,uint256)"
                    )
                ),
                responseData
            )
        );
        assertTrue(success);

        // Verify balance drop was handled
        assertTrue(responseContract.wasBalanceDropHandled(vaultAddr));

        // Verify vault is NOT paused (event-only response)
        assertFalse(
            MockVault(vaultAddr).paused(),
            "Vault should not be paused"
        );

        // Verify withdrawals still work normally
        address user = address(0x1234);
        vm.prank(user);
        MockVault(vaultAddr).withdraw(10000e6);
        assertEq(MockUSDC(tokenAddr).balanceOf(user), 10000e6);
        assertEq(MockUSDC(tokenAddr).balanceOf(vaultAddr), 70000e6);
    }

    // FILE: drosera.toml
    // [traps.sudden_balance_drop]
    // path = "out/SuddenBalanceDropTrap.sol/SuddenBalanceDropTrap.json"
    // response_contract = "0xresponsecontractaddress0000000000000000"
    // response_function = "handleBalanceDropWithPause(address,uint256,uint256)"
    // cooldown_period_blocks = 50
    // min_number_of_operators = 1
    // max_number_of_operators = 5
    // block_sample_size = 2
    //
    // forge test --contracts ./test/SuddenBalanceDropTrap.t.sol --match-test test_PauseResponse -vvvv
    function test_PauseResponse() public {
        // Get the monitored vault info from the trap (uses etched addresses)
        SuddenBalanceDropTrap.VaultInfo[] memory vaults = trap
            .getMonitoredVaults();
        address vaultAddr = vaults[0].vault;
        address tokenAddr = vaults[0].token;

        // Mint initial balance of 100k USDC to the etched vault
        MockUSDC(tokenAddr).mint(vaultAddr, 100000e6);

        // Get first data collection with 100k balance
        bytes memory data1 = trap.collect();

        // Simulate balance drop - transfer 20k to reduce vault balance to 80k (20% drop)
        vm.roll(block.number + 1);
        vm.prank(vaultAddr);
        MockUSDC(tokenAddr).transfer(address(0xdead), 20000e6);

        bytes memory data2 = trap.collect();

        bytes[] memory dataArray = new bytes[](2);
        dataArray[0] = data2;
        dataArray[1] = data1;

        (bool shouldTrigger, bytes memory responseData) = trap.shouldRespond(
            dataArray
        );
        assertTrue(shouldTrigger, "Trap should trigger for balance drop");

        // Verify we can decode the response data
        (address vault, uint256 oldBalance, uint256 newBalance) = abi.decode(
            responseData,
            (address, uint256, uint256)
        );
        assertEq(vault, vaultAddr, "Vault should be the etched vault");
        assertEq(oldBalance, 100000e6, "Old balance should be 100k");
        assertEq(newBalance, 80000e6, "New balance should be 80k");

        // Verify vault is not paused before response
        assertFalse(
            MockVault(vaultAddr).paused(),
            "Vault should not be paused initially"
        );

        // This is how the Drosera operator would call the response contract:
        // It combines the function selector with the response data from shouldRespond
        vm.prank(MOCK_TRAP_CONFIG);
        (bool success, ) = address(responseContract).call(
            abi.encodePacked(
                bytes4(
                    keccak256(
                        "handleBalanceDropWithPause(address,uint256,uint256)"
                    )
                ),
                responseData
            )
        );
        assertTrue(success, "Response contract call should succeed");

        // Verify balance drop was handled
        assertTrue(responseContract.wasBalanceDropHandled(vaultAddr));

        // Verify vault was paused by the response contract
        assertTrue(
            MockVault(vaultAddr).paused(),
            "Vault should be paused after balance drop"
        );

        // Demonstrate that the paused vault blocks withdrawals
        address user = address(0x1234);
        vm.prank(user);
        vm.expectRevert("Vault is paused");
        MockVault(vaultAddr).withdraw(10000e6);

        // Verify vault balance remains unchanged after failed withdrawal
        assertEq(MockUSDC(tokenAddr).balanceOf(vaultAddr), 80000e6);
    }

    // FILE: drosera.toml
    // [traps.sudden_balance_drop]
    // path = "out/SuddenBalanceDropTrap.sol/SuddenBalanceDropTrap.json"
    // response_contract = "0xresponsecontractaddress0000000000000000"
    // response_function = "handleBalanceDropWithCircuitBreaker(address,uint256,uint256)"
    // cooldown_period_blocks = 50
    // min_number_of_operators = 1
    // max_number_of_operators = 5
    // block_sample_size = 2
    //
    // forge test --contracts ./test/SuddenBalanceDropTrap.t.sol --match-test test_CircuitBreakerResponse -vvvv
    function test_CircuitBreakerResponse() public {
        // Get the monitored vault info from the trap
        SuddenBalanceDropTrap.VaultInfo[] memory vaults = trap
            .getMonitoredVaults();
        address vaultAddr = vaults[0].vault;
        address tokenAddr = vaults[0].token;

        // Mint initial balance
        MockUSDC(tokenAddr).mint(vaultAddr, 100000e6);

        // Get first data collection
        bytes memory data1 = trap.collect();

        // Simulate balance drop
        vm.roll(block.number + 1);
        vm.prank(vaultAddr);
        MockUSDC(tokenAddr).transfer(address(0xdead), 20000e6);

        bytes memory data2 = trap.collect();

        bytes[] memory dataArray = new bytes[](2);
        dataArray[0] = data2;
        dataArray[1] = data1;

        (bool shouldTrigger, bytes memory responseData) = trap.shouldRespond(
            dataArray
        );
        assertTrue(shouldTrigger);

        // Call the circuit breaker response instead of pause
        vm.prank(MOCK_TRAP_CONFIG);
        (bool success, ) = address(responseContract).call(
            abi.encodePacked(
                bytes4(
                    keccak256(
                        "handleBalanceDropWithCircuitBreaker(address,uint256,uint256)"
                    )
                ),
                responseData
            )
        );
        assertTrue(success);

        // Verify circuit breaker is active
        assertTrue(
            MockVault(vaultAddr).isCircuitBreakerActive(),
            "Circuit breaker should be active"
        );

        // Try to withdraw - should fail due to circuit breaker
        address user = address(0x5678);
        vm.prank(user);
        vm.expectRevert("Vault is frozen by circuit breaker");
        MockVault(vaultAddr).withdraw(10000e6);

        // Fast forward 32 blocks
        vm.roll(block.number + 32);

        // Now withdrawal should work
        vm.prank(user);
        MockVault(vaultAddr).withdraw(10000e6);
        assertEq(MockUSDC(tokenAddr).balanceOf(user), 10000e6);
        assertEq(MockUSDC(tokenAddr).balanceOf(vaultAddr), 70000e6);
    }

    // FILE: drosera.toml
    // [traps.sudden_balance_drop]
    // path = "out/SuddenBalanceDropTrap.sol/SuddenBalanceDropTrap.json"
    // response_contract = "0xresponsecontractaddress0000000000000000"
    // response_function = "handleBalanceDropWithTransfer(address,uint256,uint256)"
    // cooldown_period_blocks = 50
    // min_number_of_operators = 1
    // max_number_of_operators = 5
    // block_sample_size = 2
    //
    // forge test --contracts ./test/SuddenBalanceDropTrap.t.sol --match-test test_EmergencyTransferResponse -vvvv
    function test_EmergencyTransferResponse() public {
        // Get the monitored vault info
        SuddenBalanceDropTrap.VaultInfo[] memory vaults = trap
            .getMonitoredVaults();
        address vaultAddr = vaults[0].vault;
        address tokenAddr = vaults[0].token;

        // Mint initial balance
        MockUSDC(tokenAddr).mint(vaultAddr, 100000e6);

        // Get owner address (this test contract)
        address vaultOwner = address(this);

        // Verify initial balances
        assertEq(MockUSDC(tokenAddr).balanceOf(vaultAddr), 100000e6);
        assertEq(MockUSDC(tokenAddr).balanceOf(vaultOwner), 0);

        // Collect data before drop
        bytes memory data1 = trap.collect();

        // Simulate balance drop
        vm.roll(block.number + 1);
        vm.prank(vaultAddr);
        MockUSDC(tokenAddr).transfer(address(0xdead), 20000e6);

        // Collect data after drop
        bytes memory data2 = trap.collect();

        bytes[] memory dataArray = new bytes[](2);
        dataArray[0] = data2;
        dataArray[1] = data1;

        (bool shouldTrigger, bytes memory responseData) = trap.shouldRespond(
            dataArray
        );
        assertTrue(shouldTrigger);

        // Call the emergency transfer response
        vm.prank(MOCK_TRAP_CONFIG);
        (bool success, ) = address(responseContract).call(
            abi.encodePacked(
                bytes4(
                    keccak256(
                        "handleBalanceDropWithTransfer(address,uint256,uint256)"
                    )
                ),
                responseData
            )
        );
        assertTrue(success);

        // Verify all remaining funds were transferred to owner
        assertEq(
            MockUSDC(tokenAddr).balanceOf(vaultAddr),
            0,
            "Vault should be empty"
        );
        assertEq(
            MockUSDC(tokenAddr).balanceOf(vaultOwner),
            80000e6,
            "Owner should have all remaining funds"
        );

        // Verify the vault can no longer be used for withdrawals (no funds)
        address user = address(0x9999);
        vm.prank(user);
        vm.expectRevert("Insufficient balance");
        MockVault(vaultAddr).withdraw(1000e6);
    }
}
