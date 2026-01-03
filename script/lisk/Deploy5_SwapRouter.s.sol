// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/SwapRouter.sol";

interface IIdentityRegistry {
    function registerIdentity(address user) external;
}

/**
 * @title Deploy5_SwapRouter
 * @dev Deploy SwapRouter to Lisk Sepolia
 * @notice Requires UNISWAP_ROUTER, MOCK_IDRX, MOCK_USDC, and MockXAUT to be set in .env
 */
contract Deploy5_SwapRouter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        address idrx = vm.envAddress("MOCK_IDRX");
        address usdc = vm.envAddress("MOCK_USDC");
        address xaut = vm.envAddress("XAUT");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        require(uniswapRouter != address(0), "UNISWAP_ROUTER not set in .env");
        require(idrx != address(0), "MOCK_IDRX not set in .env");
        require(usdc != address(0), "MOCK_USDC not set in .env");
        require(xaut != address(0), "XAUT not set in .env");
        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set in .env");
        
        console.log("==============================================");
        console.log("Deploying SwapRouter to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");
        console.log("Dependencies:");
        console.log("  Uniswap Router:", uniswapRouter);
        console.log("  IDRX:", idrx);
        console.log("  USDC:", usdc);
        console.log("  XAUT:", xaut);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        SwapRouter swapRouter = new SwapRouter(
            uniswapRouter,
            idrx,
            usdc,
            xaut
        );
        
        // Register SwapRouter in KYC
        IIdentityRegistry(identityRegistry).registerIdentity(address(swapRouter));
        console.log("SwapRouter registered in KYC");
        
        vm.stopBroadcast();

        console.log("");
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("SwapRouter deployed at:", address(swapRouter));
        console.log("");
        console.log("Add to .env file:");
        console.log("SWAP_ROUTER=", address(swapRouter));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(swapRouter));
        console.log("==============================================");
    }
}
