// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/BorrowingProtocolV2.sol";

/**
 * @title DeployBorrowingProtocolV2
 * @notice Deployment script for BorrowingProtocol V2 on Mantle Sepolia
 * 
 * Usage:
 *   forge script script/DeployBorrowingProtocolV2.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast \
 *     --verify
 */
contract DeployBorrowingProtocolV2 is Script {
    // Mantle Sepolia Contract Addresses
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    
    // Treasury = Deployer wallet
    address constant TREASURY = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;
    
    // Initial XAUT price: 42,660,000 IDRX (with 8 decimals)
    // This represents ~$2,700 USD gold price
    uint256 constant INITIAL_PRICE = 4_266_000_000_000_000;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("===========================================");
        console.log("  BorrowingProtocol V2 Deployment");
        console.log("  Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("===========================================");
        console.log("");
        
        console.log("Configuration:");
        console.log("  XAUT:             ", XAUT);
        console.log("  IDRX:             ", IDRX);
        console.log("  IdentityRegistry: ", IDENTITY_REGISTRY);
        console.log("  Treasury:         ", TREASURY);
        console.log("  Initial Price:    ", INITIAL_PRICE, "(42.66M IDRX per XAUT)");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy BorrowingProtocol V2
        // Constructor order: (xaut, idrx, identityRegistry, treasury, initialPrice)
        BorrowingProtocolV2 protocol = new BorrowingProtocolV2(
            XAUT,
            IDRX,
            IDENTITY_REGISTRY,
            TREASURY,
            INITIAL_PRICE
        );
        
        vm.stopBroadcast();
        
        console.log("===========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("===========================================");
        console.log("");
        console.log("BorrowingProtocol V2 deployed at:");
        console.log("  ", address(protocol));
        console.log("");
        
        // Verify configuration
        console.log("Verification:");
        console.log("  Admin:            ", protocol.admin());
        console.log("  Treasury:         ", protocol.treasury());
        console.log("  Borrow Fee:       ", protocol.borrowFeeBps(), "bps (0.5%)");
        console.log("  XAUT Price:       ", protocol.xautPriceInIDRX());
        console.log("  Last Price Update:", protocol.lastPriceUpdate());
        console.log("  MAX_LTV:          ", protocol.MAX_LTV(), "bps (75%)");
        console.log("  WARNING_LTV:      ", protocol.WARNING_LTV(), "bps (80%)");
        console.log("  LIQUIDATION_LTV:  ", protocol.LIQUIDATION_LTV(), "bps (90%)");
        console.log("");
        
        console.log("===========================================");
        console.log("  NEXT STEPS:");
        console.log("===========================================");
        console.log("");
        console.log("1. Register BorrowingProtocol V2 in IdentityRegistry:");
        console.log("   cast send 0x620870d419F6aFca8AFed5B516619aa50900cadc \\");
        console.log("     'batchRegisterIdentity(address[])' \\");
        console.log("     '[<PROTOCOL_ADDRESS>]' \\");
        console.log("     --private-key $PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC");
        console.log("");
        console.log("2. Approve BorrowingProtocol V2 from Treasury:");
        console.log("   cast send 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05 \\");
        console.log("     'approve(address,uint256)' \\");
        console.log("     <PROTOCOL_ADDRESS> \\");
        console.log("     115792089237316195423570985008687907853269984665640564039457584007913129639935 \\");
        console.log("     --private-key $PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC");
        console.log("");
        console.log("3. Update frontend with new contract address");
        console.log("");
        console.log("===========================================");
        console.log("  V2 NEW FUNCTIONS:");
        console.log("===========================================");
        console.log("");
        console.log("depositAndBorrow(uint256 collateral, uint256 borrow)");
        console.log("  - Deposit XAUT and borrow IDRX in single TX");
        console.log("  - Requires prior XAUT approval");
        console.log("");
        console.log("repayAndWithdraw(uint256 repay, uint256 withdraw)");
        console.log("  - Repay IDRX and withdraw XAUT in single TX");
        console.log("  - Requires prior IDRX approval for repayment");
        console.log("");
        console.log("closePosition()");
        console.log("  - Repay all debt and withdraw all collateral");
        console.log("  - Requires prior IDRX approval for full debt amount");
        console.log("");
        console.log("previewDepositAndBorrow(user, collateral, borrow)");
        console.log("  - Returns: (amountReceived, fee, newLTV, allowed)");
        console.log("");
        console.log("previewRepayAndWithdraw(user, repay, withdraw)");
        console.log("  - Returns: (success, newLTV)");
        console.log("");
    }
}
