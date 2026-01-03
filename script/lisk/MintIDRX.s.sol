// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/MockIDRX.sol";

contract MintIDRX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address idrxAddress = vm.envAddress("MOCK_IDRX");
        address recipient = vm.envAddress("DEPLOYER");
        
        // Amount: 1,000,000,000 IDRX (with 6 decimals)
        uint256 amount = 1_000_000_000 * 10**6;
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockIDRX idrx = MockIDRX(idrxAddress);
        
        console.log("=== Minting IDRX ===");
        console.log("IDRX Address:", idrxAddress);
        console.log("Recipient:", recipient);
        console.log("Amount (raw):", amount);
        console.log("Amount (formatted): 1,000,000,000 IDRX");
        
        // Use publicMint (no owner required)
        idrx.publicMint(recipient, amount);
        
        console.log("\n=== Mint Successful ===");
        console.log("Balance:", idrx.balanceOf(recipient));
        
        vm.stopBroadcast();
    }
}
