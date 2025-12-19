// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GoldVault.sol";
import "../src/SwapRouter.sol";
import "../src/IdentityRegistry.sol";

contract VerifyVaultRouter is Script {
    // Update these addresses after deployment
    address constant GOLD_VAULT = 0xa039F4E162F8A8C5d01C57b78daDa8dcc976657a;
    address constant SWAP_ROUTER = 0x2737e491775055F7218b40A11DE10dA855968277;

    // Existing deployed addresses
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant UNISWAP_ROUTER = 0xF01D09A6CF3938d59326126174bD1b32FB47d8F5;
    address constant USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;

    function run() external view {
        require(GOLD_VAULT != address(0), "Update GOLD_VAULT address");
        require(SWAP_ROUTER != address(0), "Update SWAP_ROUTER address");

        console.log("========================================");
        console.log(" Verifying GoldVault");
        console.log("========================================");

        GoldVault vault = GoldVault(GOLD_VAULT);

        console.log("Contract:", address(vault));
        console.log("Name:", vault.name());
        console.log("Symbol:", vault.symbol());
        console.log("Asset (XAUT):", vault.asset());
        console.log("Total Assets:", vault.totalAssets());
        console.log("Total Supply:", vault.totalSupply());
        console.log("Identity Registry:", address(vault.identityRegistry()));
        console.log("Uniswap Router:", address(vault.uniswapRouter()));
        console.log("USDC:", vault.usdcToken());

        // Verify constructor parameters
        require(vault.asset() == XAUT, "XAUT mismatch");
        require(address(vault.identityRegistry()) == IDENTITY_REGISTRY, "IdentityRegistry mismatch");
        require(address(vault.uniswapRouter()) == UNISWAP_ROUTER, "UniswapRouter mismatch");
        require(vault.usdcToken() == USDC, "USDC mismatch");

        console.log("\n[OK] GoldVault verification passed!");

        console.log("\n========================================");
        console.log(" Verifying SwapRouter");
        console.log("========================================");

        SwapRouter router = SwapRouter(SWAP_ROUTER);

        console.log("Contract:", address(router));
        console.log("Uniswap Router:", address(router.uniswapRouter()));
        console.log("IDRX:", address(router.idrx()));
        console.log("USDC:", address(router.usdc()));
        console.log("XAUT:", address(router.xaut()));

        // Verify constructor parameters
        require(address(router.uniswapRouter()) == UNISWAP_ROUTER, "UniswapRouter mismatch");
        require(address(router.idrx()) == IDRX, "IDRX mismatch");
        require(address(router.usdc()) == USDC, "USDC mismatch");
        require(address(router.xaut()) == XAUT, "XAUT mismatch");

        console.log("\n[OK] SwapRouter verification passed!");

        console.log("\n========================================");
        console.log(" Checking Identity Registration");
        console.log("========================================");

        IdentityRegistry identityRegistry = IdentityRegistry(IDENTITY_REGISTRY);

        bool vaultVerified = identityRegistry.isVerified(GOLD_VAULT);
        bool routerVerified = identityRegistry.isVerified(SWAP_ROUTER);

        console.log("GoldVault verified:", vaultVerified);
        console.log("SwapRouter verified:", routerVerified);

        if (vaultVerified && routerVerified) {
            console.log("\n[OK] All contracts are registered!");
        } else {
            console.log("\n[WARNING] Some contracts not registered yet.");
            console.log("Run: setup-vault-router.bat");
        }

        console.log("\n========================================");
        console.log(" All Verifications Complete!");
        console.log("========================================");
    }
}
