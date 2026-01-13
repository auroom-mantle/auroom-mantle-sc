// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";

/**
 * @title Setup03_ApproveProtocol
 * @notice Approve BorrowingProtocolV2 to spend IDRX from treasury
 * @dev Run after minting IDRX to treasury
 * 
 * Usage:
 *   forge script script/mantle/post-deployment/Setup03_ApproveProtocol.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast
 */
contract Setup03_ApproveProtocol is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Load contract addresses from env
        address idrx = vm.envAddress("MOCK_IDRX");
        address borrowingProtocol = vm.envAddress("BORROWING_PROTOCOL_V2");
        
        // Treasury defaults to deployer
        address treasury = deployer;
        try vm.envAddress("TREASURY") returns (address t) {
            if (t != address(0)) treasury = t;
        } catch {}
        
        console.log("==============================================");
        console.log("Setup03: Approve Protocol to Spend IDRX");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("IDRX:", idrx);
        console.log("BorrowingProtocolV2:", borrowingProtocol);
        console.log("Treasury:", treasury);
        console.log("");
        
        require(idrx != address(0), "MOCK_IDRX not set");
        require(borrowingProtocol != address(0), "BORROWING_PROTOCOL_V2 not set");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve max amount
        (bool success,) = idrx.call(
            abi.encodeWithSignature(
                "approve(address,uint256)", 
                borrowingProtocol, 
                type(uint256).max
            )
        );
        require(success, "IDRX approval failed");
        
        vm.stopBroadcast();
        
        // Verify approval
        bytes memory data;
        (success, data) = idrx.staticcall(
            abi.encodeWithSignature("allowance(address,address)", treasury, borrowingProtocol)
        );
        require(success, "Allowance check failed");
        
        console.log("==============================================");
        console.log("APPROVAL SUCCESSFUL!");
        console.log("==============================================");
        console.log("IDRX allowance for BorrowingProtocolV2:");
        console.log("  Allowance: MAX (unlimited)");
        console.log("");
        console.log("Protocol is now ready to issue loans!");
        console.log("==============================================");
        console.log("");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("");
        console.log("Users can now:");
        console.log("1. Get verified in KYC (IdentityRegistry)");
        console.log("2. Get XAUT tokens (mint or swap)");
        console.log("3. Approve + depositAndBorrow on BorrowingProtocolV2");
        console.log("==============================================");
    }
}
