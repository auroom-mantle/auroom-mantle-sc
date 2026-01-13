// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../test/mocks/MockUniswapV2Router02.sol";

/**
 * @title Deploy06_UniswapV2Router
 * @notice Deploy Mock Uniswap V2 Router to Mantle Sepolia
 * @dev Requires UNISWAP_FACTORY to be deployed first
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy06_UniswapV2Router.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast
 */
contract Deploy06_UniswapV2Router is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address factory = vm.envAddress("UNISWAP_FACTORY");
        
        console.log("==============================================");
        console.log("Deploy06: Uniswap V2 Router");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "MNT");
        console.log("Factory:", factory);
        console.log("");
        
        require(factory != address(0), "UNISWAP_FACTORY not set in .env");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Router with Factory only (no WETH needed for ERC20-only swaps)
        MockUniswapV2Router02 router = new MockUniswapV2Router02(factory);
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("UniswapV2Router02 deployed at:", address(router));
        console.log("");
        console.log("Configuration:");
        console.log("  Factory:", router.factory());
        console.log("");
        console.log("Add to .env file:");
        console.log("UNISWAP_ROUTER=", address(router));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(router));
        console.log("==============================================");
    }
}
