// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/MockUSDC.sol";

/**
 * @title Deploy2_MockUSDC
 * @dev Deploy MockUSDC token to Lisk Sepolia
 */
contract Deploy2_MockUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("==============================================");
        console.log("Deploying MockUSDC to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        MockUSDC usdc = new MockUSDC();
        
        vm.stopBroadcast();

        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("MockUSDC deployed at:", address(usdc));
        console.log("");
        console.log("Add to .env file:");
        console.log("MOCK_USDC=", address(usdc));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(usdc));
        console.log("==============================================");
    }
}
