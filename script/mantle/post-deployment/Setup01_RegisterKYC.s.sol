// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";

/**
 * @title Setup01_RegisterKYC
 * @notice Register BorrowingProtocolV2 and SwapRouter in IdentityRegistry
 * @dev Run after deploying all contracts
 * 
 * Usage:
 *   forge script script/mantle/post-deployment/Setup01_RegisterKYC.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast
 */
contract Setup01_RegisterKYC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Load contract addresses from env
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        address borrowingProtocol = vm.envAddress("BORROWING_PROTOCOL_V2");
        address swapRouter = vm.envAddress("SWAP_ROUTER");
        
        console.log("==============================================");
        console.log("Setup01: Register Contracts in KYC");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("IdentityRegistry:", identityRegistry);
        console.log("BorrowingProtocolV2:", borrowingProtocol);
        console.log("SwapRouter:", swapRouter);
        console.log("");
        
        require(identityRegistry != address(0), "IDENTITY_REGISTRY not set");
        require(borrowingProtocol != address(0), "BORROWING_PROTOCOL_V2 not set");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Register BorrowingProtocolV2 (needed to receive XAUT collateral)
        (bool success,) = identityRegistry.call(
            abi.encodeWithSignature("registerIdentity(address)", borrowingProtocol)
        );
        if (success) {
            console.log("Registered BorrowingProtocolV2 in KYC");
        } else {
            console.log("BorrowingProtocolV2 already registered or registration failed");
        }
        
        // Register SwapRouter if provided (might be already registered during deployment)
        if (swapRouter != address(0)) {
            (success,) = identityRegistry.call(
                abi.encodeWithSignature("registerIdentity(address)", swapRouter)
            );
            if (success) {
                console.log("Registered SwapRouter in KYC");
            } else {
                console.log("SwapRouter already registered or registration failed");
            }
        }
        
        vm.stopBroadcast();
        
        // Verify registrations
        (bool isVerified,) = identityRegistry.staticcall(
            abi.encodeWithSignature("isVerified(address)", borrowingProtocol)
        );
        console.log("");
        console.log("Verification:");
        console.log("  BorrowingProtocolV2 verified:", isVerified);
        
        if (swapRouter != address(0)) {
            (isVerified,) = identityRegistry.staticcall(
                abi.encodeWithSignature("isVerified(address)", swapRouter)
            );
            console.log("  SwapRouter verified:", isVerified);
        }
        
        console.log("");
        console.log("==============================================");
        console.log("SETUP COMPLETE!");
        console.log("==============================================");
    }
}
