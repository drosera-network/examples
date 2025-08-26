// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {MEVDetectionTrap} from "../src/MEVDetectionTrap.sol";
import {SandwichAttackTrap} from "../src/SandwichAttackTrap.sol";
import {MEVResponse} from "../src/MEVResponse.sol";

contract DeployScript is Script {
    MEVDetectionTrap public mevTrap;
    SandwichAttackTrap public sandwichTrap;
    MEVResponse public mevResponse;
    
    address public mevTrapAddress;
    address public sandwichTrapAddress;
    address public mevResponseAddress;
    
    address public deployer;
    address public trapConfig;
    
    function setUp() public {
        deployer = msg.sender;
        trapConfig = deployer; // For now, deployer is also trap config
    }
    
    function run() public {
        console2.log("Starting MEV Detection Trap deployment...");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployer);
        
        // Deploy MEV Response contract first
        console2.log("Deploying MEVResponse contract...");
        mevResponse = new MEVResponse(trapConfig);
        mevResponseAddress = address(mevResponse);
        console2.log("MEVResponse deployed at:", mevResponseAddress);
        
        // Deploy main MEV Detection Trap
        console2.log("Deploying MEVDetectionTrap contract...");
        mevTrap = new MEVDetectionTrap();
        mevTrapAddress = address(mevTrap);
        console2.log("MEVDetectionTrap deployed at:", mevTrapAddress);
        
        // Deploy specialized Sandwich Attack Trap
        console2.log("Deploying SandwichAttackTrap contract...");
        sandwichTrap = new SandwichAttackTrap();
        sandwichTrapAddress = address(sandwichTrap);
        console2.log("SandwichAttackTrap deployed at:", sandwichTrapAddress);
        
        vm.stopBroadcast();
        
        console2.log("Configuring contracts...");
        _configureContracts();
        _displayDeploymentSummary();
        _saveDeploymentAddresses();
    }
    
    function _configureContracts() internal {
        vm.startBroadcast(deployer);
        
        console2.log("Adding popular DEX addresses...");
        
        // Uniswap V2 Router
        mevTrap.addMonitoredDEX(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        // Uniswap V3 Router
        mevTrap.addMonitoredDEX(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        
        // SushiSwap Router
        mevTrap.addMonitoredDEX(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        
        // Add some known MEV bot addresses (this would be updated with real addresses)
        console2.log("Adding known MEV bot addresses...");
        mevTrap.addKnownMEVBot(0x0000000000000000000000000000000000000000); 
        
        console2.log("Adding popular DEX pairs...");
        
        // Example pairs (replace with real addresses)
        sandwichTrap.addMonitoredAddress(0x0000000000000000000000000000000000000000);
        sandwichTrap.addMonitoredAddress(0x0000000000000000000000000000000000000000);
        sandwichTrap.addMonitoredAddress(0x0000000000000000000000000000000000000000);
        
        vm.stopBroadcast();
        
        console2.log("Contract configuration completed");
    }
    
    function _displayDeploymentSummary() internal view {
        console2.log("\nDeployment Summary");
        console2.log("=====================");
        console2.log("Chain ID:", block.chainid);
        console2.log("Deployer:", deployer);
        console2.log("Trap Config:", trapConfig);
        console2.log("");
        console2.log("MEVResponse:", mevResponseAddress);
        console2.log("MEVDetectionTrap:", mevTrapAddress);
        console2.log("SandwichAttackTrap:", sandwichTrapAddress);
        console2.log("");
        console2.log("Monitored DEXs:", mevTrap.getMonitoredDEXs().length);
        console2.log("Known MEV Bots:", mevTrap.getKnownMEVBots().length);
        console2.log("Monitored Addresses:", sandwichTrap.getMonitoredAddresses().length);
        console2.log("");
        console2.log("Next Steps:");
        console2.log("1. Update drosera.toml with deployed addresses");
        console2.log("2. Configure response contract addresses");
        console2.log("3. Set up monitoring and alerts");
        console2.log("4. Test with real MEV scenarios");
    }
    
    function _saveDeploymentAddresses() internal {
        string memory deploymentInfo = string(abi.encodePacked(
            "MEV Detection Trap Deployment\n",
            "=============================\n",
            "Chain ID: ", vm.toString(block.chainid), "\n",
            "Deployer: ", vm.toString(deployer), "\n",
            "Trap Config: ", vm.toString(trapConfig), "\n\n",
            "MEVResponse: ", vm.toString(mevResponseAddress), "\n",
            "MEVDetectionTrap: ", vm.toString(mevTrapAddress), "\n",
            "SandwichAttackTrap: ", vm.toString(sandwichTrapAddress), "\n\n",
            "Deployment Time: ", vm.toString(block.timestamp), "\n"
        ));
        
        vm.writeFile("deployment.txt", deploymentInfo);
        console2.log("Deployment addresses saved to deployment.txt");
    }
    
    function verify() public {
        console2.log("Verifying contracts on Etherscan...");

        console2.log("MEVResponse verification command:");
        console2.log("forge verify-contract", mevResponseAddress, "src/MEVResponse.sol:MEVResponse --chain-id", block.chainid);
        
        console2.log("MEVDetectionTrap verification command:");
        console2.log("forge verify-contract", mevTrapAddress, "src/MEVDetectionTrap.sol:MEVDetectionTrap --chain-id", block.chainid);
        
        console2.log("SandwichAttackTrap verification command:");
        console2.log("forge verify-contract", sandwichTrapAddress, "src/SandwichAttackTrap.sol:SandwichAttackTrap --chain-id", block.chainid);
    }
    
    function generateDroseraConfig() public view {
        console2.log("\nUpdate your drosera.toml with these addresses:");
        console2.log("");
        console2.log("[traps.mev_detection_monitor]");
        console2.log("path = \"out/MEVDetectionTrap.sol/MEVDetectionTrap.json\"");
        console2.log("response_contract = \"", mevResponseAddress, "\"");
        console2.log("response_function = \"handleMEVAlert(bytes)\"");
        console2.log("address = \"", mevTrapAddress, "\"");
        console2.log("");
        console2.log("[traps.sandwich_attack_monitor]");
        console2.log("path = \"out/SandwichAttackTrap.sol/SandwichAttackTrap.json\"");
        console2.log("response_contract = \"", mevResponseAddress, "\"");
        console2.log("response_function = \"handleMEVAlert(bytes)\"");
        console2.log("address = \"", sandwichTrapAddress, "\"");
    }
}
