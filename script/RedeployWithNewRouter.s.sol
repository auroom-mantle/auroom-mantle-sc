// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/SwapRouter.sol";
import "../src/GoldVault.sol";

/**
 * @title RedeployWithNewRouter
 * @notice Redeploy SwapRouter and GoldVault with new Router V2 address
 * @dev Router V2: 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9
 */
contract RedeployWithNewRouter is Script {
    // Existing deployed contracts (unchanged)
    address constant IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;

    // NEW Router V2 (Full Implementation)
    address constant UNISWAP_ROUTER_V2 = 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9;

    // Old addresses (for reference)
    address constant OLD_ROUTER = 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Redeploy with Router V2 ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        console.log("\n=== Router Upgrade ===");
        console.log("Old Router:", OLD_ROUTER, "(DEPRECATED)");
        console.log("New Router V2:", UNISWAP_ROUTER_V2, "(ACTIVE)");

        console.log("\n=== Existing Contracts (Unchanged) ===");
        console.log("IDRX:", IDRX);
        console.log("USDC:", USDC);
        console.log("XAUT:", XAUT);
        console.log("IdentityRegistry:", IDENTITY_REGISTRY);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy SwapRouter with new Router V2
        console.log("\n=== 1. Deploying SwapRouter ===");
        SwapRouter swapRouter = new SwapRouter(
            UNISWAP_ROUTER_V2,  // New Router V2
            IDRX,
            USDC,
            XAUT
        );
        console.log("SwapRouter deployed at:", address(swapRouter));

        // 2. Deploy GoldVault with new Router V2
        console.log("\n=== 2. Deploying GoldVault ===");
        GoldVault goldVault = new GoldVault(
            XAUT,
            IDENTITY_REGISTRY,
            UNISWAP_ROUTER_V2,  // New Router V2
            USDC
        );
        console.log("GoldVault deployed at:", address(goldVault));

        vm.stopBroadcast();

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("SwapRouter (NEW):", address(swapRouter));
        console.log("GoldVault (NEW):", address(goldVault));
        console.log("Router V2:", UNISWAP_ROUTER_V2);

        console.log("\n=== Next Steps ===");
        console.log("1. Register SwapRouter in IdentityRegistry:");
        console.log("   cast send", IDENTITY_REGISTRY, "\\");
        console.log("     'registerIdentity(address)'", address(swapRouter), "\\");
        console.log("     --private-key $PRIVATE_KEY --rpc-url $RPC");
        console.log("");
        console.log("2. Register GoldVault in IdentityRegistry:");
        console.log("   cast send", IDENTITY_REGISTRY, "\\");
        console.log("     'registerIdentity(address)'", address(goldVault), "\\");
        console.log("     --private-key $PRIVATE_KEY --rpc-url $RPC");
        console.log("");
        console.log("3. Update test files with new addresses");
        console.log("4. Run: forge test");
    }
}
