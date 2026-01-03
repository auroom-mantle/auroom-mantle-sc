// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/IdentityRegistry.sol";

/**
 * @title Deploy3_IdentityRegistry
 * @dev Deploy IdentityRegistry to Lisk Sepolia
 */
contract Deploy3_IdentityRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==============================================");
        console.log("Deploying IdentityRegistry to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        IdentityRegistry identityRegistry = new IdentityRegistry();
        
        // Register deployer in KYC
        identityRegistry.registerIdentity(deployer);
        console.log("Deployer registered in KYC");
        
        vm.stopBroadcast();

        console.log("");
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("IdentityRegistry deployed at:", address(identityRegistry));
        console.log("");
        console.log("Add to .env file:");
        console.log("IDENTITY_REGISTRY=", address(identityRegistry));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(identityRegistry));
        console.log("==============================================");
    }
}
