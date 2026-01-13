// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../src/MockUSDC.sol";

/**
 * @title Deploy02_MockUSDC
 * @notice Deploy MockUSDC token to Mantle Sepolia
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy02_MockUSDC.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy02_MockUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==============================================");
        console.log("Deploy02: MockUSDC Token");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "MNT");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockUSDC usdc = new MockUSDC();
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("MockUSDC deployed at:", address(usdc));
        console.log("");
        console.log("Token Info:");
        console.log("  Name:", usdc.name());
        console.log("  Symbol:", usdc.symbol());
        console.log("  Decimals:", usdc.decimals());
        console.log("");
        console.log("Add to .env file:");
        console.log("MOCK_USDC=", address(usdc));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(usdc));
        console.log("==============================================");
    }
}
