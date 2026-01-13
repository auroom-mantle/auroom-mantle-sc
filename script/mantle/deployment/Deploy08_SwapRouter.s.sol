// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../src/SwapRouter.sol";

/**
 * @title Deploy08_SwapRouter
 * @notice Deploy SwapRouter to Mantle Sepolia
 * @dev Requires all token and DEX contracts to be deployed first
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy08_SwapRouter.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy08_SwapRouter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Load contract addresses from env
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        address idrx = vm.envAddress("MOCK_IDRX");
        address usdc = vm.envAddress("MOCK_USDC");
        address xaut = vm.envAddress("XAUT");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        console.log("==============================================");
        console.log("Deploy08: SwapRouter");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("UniswapRouter:", uniswapRouter);
        console.log("IDRX:", idrx);
        console.log("USDC:", usdc);
        console.log("XAUT:", xaut);
        console.log("IdentityRegistry:", identityRegistry);
        console.log("");
        
        require(uniswapRouter != address(0), "UNISWAP_ROUTER not set");
        require(idrx != address(0), "MOCK_IDRX not set");
        require(usdc != address(0), "MOCK_USDC not set");
        require(xaut != address(0), "XAUT not set");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SwapRouter (4 args: router, idrx, usdc, xaut)
        SwapRouter swapRouter = new SwapRouter(
            uniswapRouter,
            idrx,
            usdc,
            xaut
        );
        
        // Register SwapRouter in KYC (if IDENTITY_REGISTRY is set)
        if (identityRegistry != address(0)) {
            (bool success,) = identityRegistry.call(
                abi.encodeWithSignature("registerIdentity(address)", address(swapRouter))
            );
            if (success) {
                console.log("SwapRouter registered in KYC");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("SwapRouter deployed at:", address(swapRouter));
        console.log("");
        console.log("Configuration:");
        console.log("  UniswapRouter:", address(swapRouter.uniswapRouter()));
        console.log("  IDRX:", address(swapRouter.idrx()));
        console.log("  USDC:", address(swapRouter.usdc()));
        console.log("  XAUT:", address(swapRouter.xaut()));
        console.log("");
        console.log("Add to .env file:");
        console.log("SWAP_ROUTER=", address(swapRouter));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(swapRouter));
        console.log("==============================================");
    }
}
