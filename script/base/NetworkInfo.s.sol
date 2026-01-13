// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title NetworkInfo
 * @notice Display network and account information
 * @dev Useful for pre-deployment checks
 */
contract NetworkInfo is Script {
    function run() external view {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployer == address(0)) {
            // Try to derive from private key
            uint256 privateKey = vm.envUint("PRIVATE_KEY");
            deployer = vm.addr(privateKey);
        }

        console.log("==============================================");
        console.log("Network Information");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Block Timestamp:", block.timestamp);
        console.log("Base Fee:", block.basefee);
        console.log("==============================================\n");

        console.log("==============================================");
        console.log("Deployer Information");
        console.log("==============================================");
        console.log("Address:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        console.log("Nonce:", vm.getNonce(deployer));
        console.log("==============================================\n");

        // Gas price estimation
        uint256 estimatedGasPrice = tx.gasprice;
        console.log("==============================================");
        console.log("Gas Information");
        console.log("==============================================");
        console.log("Current Gas Price:", estimatedGasPrice, "wei");
        console.log("Gas Price (Gwei):", estimatedGasPrice / 1e9, "Gwei");
        console.log("==============================================\n");

        // Estimated deployment costs
        estimateDeploymentCost(deployer, estimatedGasPrice);

        // Pre-deployment checks
        performPreDeploymentChecks(deployer);
    }

    function estimateDeploymentCost(address deployer, uint256 gasPrice) internal view {
        console.log("==============================================");
        console.log("Estimated Deployment Costs");
        console.log("==============================================");

        // Rough gas estimates (actual may vary)
        uint256 mockIDRXGas = 1_500_000;
        uint256 mockUSDCGas = 1_500_000;
        uint256 identityRegistryGas = 800_000;
        uint256 xautGas = 2_000_000;
        uint256 borrowingProtocolGas = 4_000_000;
        uint256 swapRouterGas = 1_500_000;

        uint256 totalGas = mockIDRXGas + mockUSDCGas + identityRegistryGas + xautGas + borrowingProtocolGas + swapRouterGas;

        uint256 estimatedCost = totalGas * gasPrice;
        uint256 estimatedCostWithBuffer = (estimatedCost * 120) / 100; // 20% buffer

        console.log("MockIDRX:          ~", mockIDRXGas, "gas");
        console.log("MockUSDC:          ~", mockUSDCGas, "gas");
        console.log("IdentityRegistry:  ~", identityRegistryGas, "gas");
        console.log("XAUT:              ~", xautGas, "gas");
        console.log("BorrowingProtocol: ~", borrowingProtocolGas, "gas");
        console.log("SwapRouter:        ~", swapRouterGas, "gas");
        console.log("---");
        console.log("Total Gas:         ~", totalGas, "gas");
        console.log("Estimated Cost:     ", estimatedCost / 1e18, "ETH");
        console.log("With 20% Buffer:    ", estimatedCostWithBuffer / 1e18, "ETH");
        console.log("Your Balance:       ", deployer.balance / 1e18, "ETH");

        if (deployer.balance < estimatedCostWithBuffer) {
            console.log("");
            console.log("WARNING: Insufficient balance!");
            console.log("You may need more ETH for deployment");
            console.log("Get testnet ETH from: https://faucet.quicknode.com/base/sepolia");
        } else {
            console.log("");
            console.log("Balance OK: Sufficient ETH for deployment");
        }

        console.log("==============================================\n");
    }

    function performPreDeploymentChecks(address deployer) internal view {
        console.log("==============================================");
        console.log("Pre-Deployment Checks");
        console.log("==============================================");

        bool allPassed = true;

        // Check 1: Deployer has balance
        if (deployer.balance == 0) {
            console.log("FAIL: Deployer has zero balance");
            allPassed = false;
        } else {
            console.log("PASS: Deployer has balance");
        }

        // Check 2: Environment variables set
        try vm.envString("NETWORK") returns (string memory network) {
            console.log("PASS: NETWORK env variable set:", network);
        } catch {
            console.log("WARN: NETWORK env variable not set (will use default)");
        }

        try vm.envAddress("UNISWAP_ROUTER") returns (address router) {
            if (router == address(0)) {
                console.log("FAIL: UNISWAP_ROUTER is zero address");
                allPassed = false;
            } else {
                console.log("PASS: UNISWAP_ROUTER env variable set:", router);
            }
        } catch {
            console.log("WARN: UNISWAP_ROUTER env variable not set (using default)");
        }

        // Check 3: Network is correct
        if (block.chainid == 84532) {
            console.log("PASS: Connected to Base Sepolia (Chain ID: 84532)");
        } else if (block.chainid == 8453) {
            console.log("INFO: Connected to Base Mainnet (Chain ID: 8453)");
        } else if (block.chainid == 31337) {
            console.log("INFO: Connected to Localhost (Chain ID: 31337)");
        } else {
            console.log("WARN: Unknown network (Chain ID:", block.chainid, ")");
        }

        // Check 4: Deployments directory exists
        string memory deploymentsDir = string.concat(vm.projectRoot(), "/deployments");
        if (!vm.isDir(deploymentsDir)) {
            console.log("INFO: deployments/ directory will be created");
        } else {
            console.log("PASS: deployments/ directory exists");
        }

        console.log("==============================================");

        if (allPassed) {
            console.log("");
            console.log("All critical checks passed!");
            console.log("Ready for deployment.");
        } else {
            console.log("");
            console.log("Some checks failed!");
            console.log("Please fix issues before deploying.");
        }

        console.log("==============================================\n");
    }
}
