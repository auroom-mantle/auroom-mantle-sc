// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../test/mocks/MockUniswapV2Router02.sol";

/**
 * @title DeployRouterOnly
 * @notice Deploy only the Router using existing Factory
 */
contract DeployRouterOnly is Script {
    // Existing deployed contracts
    address constant EXISTING_FACTORY = 0x8950d0D71a23085C514350df2682c3f6F1D7aBFE;
    address constant EXISTING_WMNT = 0xa2ddbfc12ab0B69c04eDCf1044382B9A38f883c3;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        console.log("\nUsing existing Factory:", EXISTING_FACTORY);
        console.log("Using existing WMNT:", EXISTING_WMNT);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Router with existing Factory and WMNT
        console.log("\nDeploying MockUniswapV2Router02 (Full Implementation)...");
        MockUniswapV2Router02 router = new MockUniswapV2Router02(EXISTING_FACTORY, EXISTING_WMNT);
        console.log("Router deployed at:", address(router));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("Factory (existing):", EXISTING_FACTORY);
        console.log("WMNT (existing):", EXISTING_WMNT);
        console.log("Router (NEW):", address(router));

        console.log("\n=== Next Steps ===");
        console.log("1. Update .env file with:");
        console.log("   UNISWAP_ROUTER=", address(router));
        console.log("2. Approve tokens to new Router");
        console.log("3. Run tests");
    }
}
