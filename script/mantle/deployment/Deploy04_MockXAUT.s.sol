// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../src/XAUT.sol";

/**
 * @title Deploy04_MockXAUT
 * @notice Deploy XAUT (Tokenized Gold) to Mantle Sepolia
 * @dev Requires IDENTITY_REGISTRY to be deployed first
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy04_MockXAUT.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy04_MockXAUT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        console.log("==============================================");
        console.log("Deploy04: XAUT (Tokenized Gold)");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "MNT");
        console.log("IdentityRegistry:", identityRegistry);
        console.log("");
        
        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set in .env");
        
        vm.startBroadcast(deployerPrivateKey);
        
        XAUT xaut = new XAUT(identityRegistry);
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("XAUT deployed at:", address(xaut));
        console.log("");
        console.log("Token Info:");
        console.log("  Name:", xaut.name());
        console.log("  Symbol:", xaut.symbol());
        console.log("  Decimals:", xaut.decimals());
        console.log("  IdentityRegistry:", address(xaut.identityRegistry()));
        console.log("");
        console.log("Add to .env file:");
        console.log("XAUT=", address(xaut));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(xaut));
        console.log("==============================================");
    }
}
