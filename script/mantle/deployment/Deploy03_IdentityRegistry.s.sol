// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../src/IdentityRegistry.sol";

/**
 * @title Deploy03_IdentityRegistry
 * @notice Deploy IdentityRegistry (KYC System) to Mantle Sepolia
 * @dev Automatically registers deployer as verified
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy03_IdentityRegistry.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy03_IdentityRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==============================================");
        console.log("Deploy03: IdentityRegistry (KYC System)");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "MNT");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        IdentityRegistry registry = new IdentityRegistry();
        
        // Auto-register deployer
        registry.registerIdentity(deployer);
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("IdentityRegistry deployed at:", address(registry));
        console.log("");
        console.log("Configuration:");
        console.log("  Owner:", registry.owner());
        console.log("  Deployer verified:", registry.isVerified(deployer));
        console.log("");
        console.log("Add to .env file:");
        console.log("IDENTITY_REGISTRY=", address(registry));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(registry));
        console.log("==============================================");
    }
}
