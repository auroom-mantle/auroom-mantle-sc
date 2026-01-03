// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/GoldVault.sol";

/**
 * @title Deploy6_GoldVault
 * @dev Deploy GoldVault to Lisk Sepolia
 * @notice Requires XAUT, IDENTITY_REGISTRY, UNISWAP_ROUTER, and MOCK_USDC to be set in .env
 */
contract Deploy6_GoldVault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address xaut = vm.envAddress("XAUT");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        address usdc = vm.envAddress("MOCK_USDC");
        
        require(xaut != address(0), "XAUT not set in .env");
        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set in .env");
        require(uniswapRouter != address(0), "UNISWAP_ROUTER not set in .env");
        require(usdc != address(0), "MOCK_USDC not set in .env");
        
        console.log("==============================================");
        console.log("Deploying GoldVault to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");
        console.log("Dependencies:");
        console.log("  XAUT:", xaut);
        console.log("  IdentityRegistry:", identityRegistry);
        console.log("  Uniswap Router:", uniswapRouter);
        console.log("  USDC:", usdc);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        GoldVault goldVault = new GoldVault(
            xaut,
            identityRegistry,
            uniswapRouter,
            usdc
        );
        
        // Register GoldVault in KYC
        IIdentityRegistry(identityRegistry).registerIdentity(address(goldVault));
        console.log("GoldVault registered in KYC");
        
        vm.stopBroadcast();

        console.log("");
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("GoldVault deployed at:", address(goldVault));
        console.log("");
        console.log("Add to .env file:");
        console.log("GOLD_VAULT=", address(goldVault));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(goldVault));
        console.log("==============================================");
    }
}
