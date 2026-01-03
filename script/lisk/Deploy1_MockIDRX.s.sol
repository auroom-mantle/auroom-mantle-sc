// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/MockIDRX.sol";

/**
 * @title Deploy1_MockIDRX
 * @dev Deploy MockIDRX token to Lisk Sepolia
 */
contract Deploy1_MockIDRX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("==============================================");
        console.log("Deploying MockIDRX to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        MockIDRX idrx = new MockIDRX();
        
        vm.stopBroadcast();

        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("MockIDRX deployed at:", address(idrx));
        console.log("");
        console.log("Add to .env file:");
        console.log("MOCK_IDRX=", address(idrx));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(idrx));
        console.log("==============================================");
    }
}
