// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../test/mocks/MockUniswapV2Factory.sol";

/**
 * @title Deploy05_UniswapV2Factory
 * @notice Deploy Mock Uniswap V2 Factory to Mantle Sepolia
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy05_UniswapV2Factory.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy05_UniswapV2Factory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==============================================");
        console.log("Deploy05: Uniswap V2 Factory");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "MNT");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockUniswapV2Factory factory = new MockUniswapV2Factory();
        
        // Set fee setter to deployer
        factory.setFeeToSetter(deployer);
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("UniswapV2Factory deployed at:", address(factory));
        console.log("");
        console.log("Configuration:");
        console.log("  Fee setter:", factory.feeToSetter());
        console.log("");
        console.log("Add to .env file:");
        console.log("UNISWAP_FACTORY=", address(factory));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(factory));
        console.log("==============================================");
    }
}
