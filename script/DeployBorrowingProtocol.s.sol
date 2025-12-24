// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/BorrowingProtocol.sol";

/**
 * @title DeployBorrowingProtocol
 * @notice Deployment script for BorrowingProtocol on Mantle Sepolia
 */
contract DeployBorrowingProtocol is Script {
    // Existing contract addresses on Mantle Sepolia
    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant GOLD_VAULT = 0xa039F4E162F8A8C5d01C57b78daDa8dcc976657a;
    address constant SWAP_ROUTER = 0x2737e491775055F7218b40A11DE10dA855968277;
    
    // Initial XAUT price: 42,660,000 IDRX per XAUT (with 8 decimals)
    // This represents ~$2,700 gold price
    // 42,660,000 * 10^8 = 4,266,000,000,000,000
    uint256 constant INITIAL_XAUT_PRICE = 4266000000000000;
    
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==============================================");
        console.log("Deploying BorrowingProtocol");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("");
        
        console.log("Contract Addresses:");
        console.log("- XAUT:", XAUT);
        console.log("- IDRX:", MOCK_IDRX);
        console.log("- IdentityRegistry:", IDENTITY_REGISTRY);
        console.log("- Treasury (deployer):", deployer);
        console.log("");
        
        console.log("Initial Configuration:");
        console.log("- XAUT Price:", INITIAL_XAUT_PRICE, "(42,660,000 IDRX with 8 decimals)");
        console.log("- MAX_LTV: 75%");
        console.log("- WARNING_LTV: 80%");
        console.log("- LIQUIDATION_LTV: 90%");
        console.log("- Borrow Fee: 0.5%");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy BorrowingProtocol
        BorrowingProtocol protocol = new BorrowingProtocol(
            XAUT,
            MOCK_IDRX,
            IDENTITY_REGISTRY,
            deployer, // Treasury = deployer initially
            INITIAL_XAUT_PRICE
        );
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("Deployment Successful!");
        console.log("==============================================");
        console.log("BorrowingProtocol:", address(protocol));
        console.log("");
        
        console.log("Contract Details:");
        console.log("- Admin:", protocol.admin());
        console.log("- Treasury:", protocol.treasury());
        console.log("- XAUT Price:", protocol.xautPriceInIDRX());
        console.log("- Borrow Fee (bps):", protocol.borrowFeeBps());
        console.log("- MAX_LTV:", protocol.MAX_LTV());
        console.log("- WARNING_LTV:", protocol.WARNING_LTV());
        console.log("- LIQUIDATION_LTV:", protocol.LIQUIDATION_LTV());
        console.log("");
        
        console.log("==============================================");
        console.log("Next Steps:");
        console.log("==============================================");
        console.log("1. Verify contract on explorer");
        console.log("2. Fund treasury with IDRX for lending");
        console.log("");
        console.log("3. Users need to:");
        console.log("   - Get verified in IdentityRegistry");
        console.log("   - Approve XAUT to BorrowingProtocol");
        console.log("   - Deposit collateral");
        console.log("   - Borrow IDRX");
        console.log("");
        console.log("4. Admin functions:");
        console.log("   - Update XAUT price regularly: setXAUTPrice()");
        console.log("   - Adjust borrow fee if needed: setBorrowFee()");
        console.log("   - Update treasury: setTreasury()");
        console.log("==============================================");
    }
}
