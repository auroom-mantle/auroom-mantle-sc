// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../../../src/BorrowingProtocolV2.sol";

/**
 * @title Deploy09_BorrowingProtocolV2
 * @notice Deploy BorrowingProtocol V2 (Cash Loan) to Mantle Sepolia
 * @dev Requires XAUT, IDRX, and IdentityRegistry to be deployed first
 * 
 * Initial XAUT price: 66,000,000 IDRX (with 8 decimals)
 * This represents: 1 XAUT = 4,000 USDC = 66,000,000 IDRX
 * (4,000 USDC * 16,500 IDRX/USDC = 66,000,000 IDRX)
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy09_BorrowingProtocolV2.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract Deploy09_BorrowingProtocolV2 is Script {
    // Initial XAUT price: 66,000,000 IDRX (with 8 decimals)
    uint256 constant INITIAL_PRICE = 6_600_000_000_000_000; // 66M with 8 decimals
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Load contract addresses from env
        address xaut = vm.envAddress("XAUT");
        address idrx = vm.envAddress("MOCK_IDRX");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        // Treasury = Deployer wallet (can be changed later)
        address treasury = deployer;
        
        console.log("==============================================");
        console.log("Deploy09: BorrowingProtocol V2 (Cash Loan)");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("Configuration:");
        console.log("  Deployer:", deployer);
        console.log("  XAUT:", xaut);
        console.log("  IDRX:", idrx);
        console.log("  IdentityRegistry:", identityRegistry);
        console.log("  Treasury:", treasury);
        console.log("  Initial Price:", INITIAL_PRICE, "(66M IDRX per XAUT)");
        console.log("");
        
        require(xaut != address(0), "XAUT not set in .env");
        require(idrx != address(0), "MOCK_IDRX not set in .env");
        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set in .env");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy BorrowingProtocol V2
        BorrowingProtocolV2 protocol = new BorrowingProtocolV2(
            xaut,
            idrx,
            identityRegistry,
            treasury,
            INITIAL_PRICE
        );
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL!");
        console.log("==============================================");
        console.log("BorrowingProtocol V2 deployed at:", address(protocol));
        console.log("");
        console.log("Verification:");
        console.log("  Admin:", protocol.admin());
        console.log("  Treasury:", protocol.treasury());
        console.log("  Borrow Fee:", protocol.borrowFeeBps(), "bps (0.5%)");
        console.log("  XAUT Price:", protocol.xautPriceInIDRX());
        console.log("  MAX_LTV:", protocol.MAX_LTV(), "bps (75%)");
        console.log("  WARNING_LTV:", protocol.WARNING_LTV(), "bps (80%)");
        console.log("  LIQUIDATION_LTV:", protocol.LIQUIDATION_LTV(), "bps (90%)");
        console.log("");
        console.log("Add to .env file:");
        console.log("BORROWING_PROTOCOL_V2=", address(protocol));
        console.log("");
        console.log("Verify on Mantle Explorer:");
        console.log("https://explorer.sepolia.mantle.xyz/address/", address(protocol));
        console.log("");
        console.log("==============================================");
        console.log("NEXT STEPS:");
        console.log("==============================================");
        console.log("Run post-deployment scripts:");
        console.log("1. Setup01_RegisterKYC.s.sol - Register protocol in KYC");
        console.log("2. Setup02_MintTreasury.s.sol - Mint IDRX to treasury");
        console.log("3. Setup03_ApproveProtocol.s.sol - Approve protocol to spend");
        console.log("==============================================");
    }
}
