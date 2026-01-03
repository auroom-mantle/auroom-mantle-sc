// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/XAUT.sol";

/**
 * @title Deploy4_MockXAUT
 * @dev Deploy MockXAUT token to Lisk Sepolia
 * @notice Requires IDENTITY_REGISTRY to be set in .env
 */
contract Deploy4_MockXAUT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set in .env");
        
        console.log("==============================================");
        console.log("Deploying MockXAUT to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("IdentityRegistry:", identityRegistry);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        XAUT xaut = new XAUT(identityRegistry);
        
        vm.stopBroadcast();

        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("MockXAUT deployed at:", address(xaut));
        console.log("");
        console.log("Add to .env file:");
        console.log("XAUT=", address(xaut));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(xaut));
        console.log("");
        console.log("Constructor args for verification:");
        console.log("IdentityRegistry:", identityRegistry);
        console.log("==============================================");
    }
}
