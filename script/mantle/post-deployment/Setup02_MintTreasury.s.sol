// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";

/**
 * @title Setup02_MintTreasury
 * @notice Mint IDRX tokens to treasury for lending pool
 * @dev Run after deploying all contracts and registering KYC
 * 
 * Usage:
 *   forge script script/mantle/post-deployment/Setup02_MintTreasury.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast
 */
contract Setup02_MintTreasury is Script {
    // Default mint amount: 100 trillion IDRX (for testing)
    uint256 constant DEFAULT_MINT_AMOUNT = 100_000_000_000_000 * 1e6; // 100T IDRX
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Load contract addresses from env
        address idrx = vm.envAddress("MOCK_IDRX");
        
        // Treasury defaults to deployer, can be overridden
        address treasury = deployer;
        try vm.envAddress("TREASURY") returns (address t) {
            if (t != address(0)) treasury = t;
        } catch {}
        
        // Mint amount can be overridden
        uint256 mintAmount = DEFAULT_MINT_AMOUNT;
        try vm.envUint("MINT_AMOUNT") returns (uint256 m) {
            if (m > 0) mintAmount = m;
        } catch {}
        
        console.log("==============================================");
        console.log("Setup02: Mint IDRX to Treasury");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("==============================================");
        console.log("");
        console.log("IDRX:", idrx);
        console.log("Treasury:", treasury);
        console.log("Mint Amount:", mintAmount / 1e6, "IDRX");
        console.log("");
        
        require(idrx != address(0), "MOCK_IDRX not set");
        
        // Get balance before
        (bool success, bytes memory data) = idrx.staticcall(
            abi.encodeWithSignature("balanceOf(address)", treasury)
        );
        require(success, "Balance check failed");
        uint256 balanceBefore = abi.decode(data, (uint256));
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Mint IDRX to treasury
        (success,) = idrx.call(
            abi.encodeWithSignature("publicMint(address,uint256)", treasury, mintAmount)
        );
        require(success, "IDRX mint failed");
        
        vm.stopBroadcast();
        
        // Get balance after
        (success, data) = idrx.staticcall(
            abi.encodeWithSignature("balanceOf(address)", treasury)
        );
        require(success, "Balance check failed");
        uint256 balanceAfter = abi.decode(data, (uint256));
        
        console.log("==============================================");
        console.log("MINT SUCCESSFUL!");
        console.log("==============================================");
        console.log("Treasury IDRX balance:");
        console.log("  Before:", balanceBefore / 1e6, "IDRX");
        console.log("  After:", balanceAfter / 1e6, "IDRX");
        console.log("  Minted:", (balanceAfter - balanceBefore) / 1e6, "IDRX");
        console.log("==============================================");
    }
}
