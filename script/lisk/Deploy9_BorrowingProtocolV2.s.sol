// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../src/BorrowingProtocolV2.sol";

/**
 * @title Deploy9_BorrowingProtocolV2
 * @dev Deploy BorrowingProtocol V2 to Lisk Sepolia
 * 
 * Initial XAUT price: 66,000,000 IDRX (with 8 decimals)
 * This represents: 1 XAUT = 4,000 USDC = 66,000,000 IDRX
 * (4,000 USDC * 16,500 IDRX/USDC = 66,000,000 IDRX)
 */
contract Deploy9_BorrowingProtocolV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Lisk Sepolia Contract Addresses
        address xaut = vm.envAddress("XAUT");
        address idrx = vm.envAddress("MOCK_IDRX");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        // Treasury = Deployer wallet
        address treasury = deployer;
        
        // Initial XAUT price: 66,000,000 IDRX (with 8 decimals)
        // 1 XAUT = 4,000 USDC = 66,000,000 IDRX
        uint256 initialPrice = 6_600_000_000_000_000; // 66M with 8 decimals
        
        console.log("==============================================");
        console.log("BorrowingProtocol V2 Deployment");
        console.log("Network: Lisk Sepolia (Chain ID: 4202)");
        console.log("==============================================");
        console.log("");
        console.log("Configuration:");
        console.log("  XAUT:             ", xaut);
        console.log("  IDRX:             ", idrx);
        console.log("  IdentityRegistry: ", identityRegistry);
        console.log("  Treasury:         ", treasury);
        console.log("  Initial Price:    ", initialPrice, "(66M IDRX per XAUT)");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy BorrowingProtocol V2
        BorrowingProtocolV2 protocol = new BorrowingProtocolV2(
            xaut,
            idrx,
            identityRegistry,
            treasury,
            initialPrice
        );
        
        // Note: Register protocol manually after deployment if needed
        // IIdentityRegistry(identityRegistry).registerIdentity(address(protocol));
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("BorrowingProtocol V2 deployed at:");
        console.log("  ", address(protocol));
        console.log("");
        console.log("Verification:");
        console.log("  Admin:            ", protocol.admin());
        console.log("  Treasury:         ", protocol.treasury());
        console.log("  Borrow Fee:       ", protocol.borrowFeeBps(), "bps (0.5%)");
        console.log("  XAUT Price:       ", protocol.xautPriceInIDRX());
        console.log("  MAX_LTV:          ", protocol.MAX_LTV(), "bps (75%)");
        console.log("  WARNING_LTV:      ", protocol.WARNING_LTV(), "bps (80%)");
        console.log("  LIQUIDATION_LTV:  ", protocol.LIQUIDATION_LTV(), "bps (90%)");
        console.log("");
        console.log("Add to .env file:");
        console.log("BORROWING_PROTOCOL_V2=", address(protocol));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(protocol));
        console.log("");
        console.log("==============================================");
        console.log("NEXT STEPS:");
        console.log("==============================================");
        console.log("1. Mint IDRX to treasury for lending");
        console.log("2. Approve BorrowingProtocol V2 to spend IDRX from treasury");
        console.log("3. Update frontend with new contract address");
        console.log("==============================================");
    }
}
