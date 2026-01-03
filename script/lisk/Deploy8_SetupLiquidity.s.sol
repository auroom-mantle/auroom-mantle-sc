// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IMintable {
    function mint(address to, uint256 amount) external;
}

interface IIdentityRegistry {
    function registerIdentity(address user) external;
    function isVerified(address user) external view returns (bool);
}

/**
 * @title Deploy8_SetupLiquidity_Proper
 * @dev Systematic liquidity setup with correct sequence
 * 
 * Ratios:
 * - 1 USDC = 16,500 IDRX
 * - 1 XAUT = 4,000 USDC
 * 
 * Amounts:
 * - IDRX: 1,000,000,000 (1B with 6 decimals)
 * - USDC: 1,000,000 (1M with 6 decimals)
 * - XAUT: 2,500 (with 6 decimals)
 */
contract Deploy8_SetupLiquidity_Proper is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        address idrx = vm.envAddress("MOCK_IDRX");
        address usdc = vm.envAddress("MOCK_USDC");
        address xaut = vm.envAddress("XAUT");
        address factory = vm.envAddress("UNISWAP_FACTORY");
        address router = vm.envAddress("UNISWAP_ROUTER");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        console.log("==============================================");
        console.log("Systematic Liquidity Setup - Lisk Sepolia");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // STEP 1: Create pairs and get addresses
        console.log("STEP 1: Creating pairs...");
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);
        
        address pairIDRX_USDC = factoryContract.getPair(idrx, usdc);
        if (pairIDRX_USDC == address(0)) {
            pairIDRX_USDC = factoryContract.createPair(idrx, usdc);
            console.log("  Created IDRX/USDC pair:", pairIDRX_USDC);
        } else {
            console.log("  IDRX/USDC pair exists:", pairIDRX_USDC);
        }

        address pairXAUT_USDC = factoryContract.getPair(xaut, usdc);
        if (pairXAUT_USDC == address(0)) {
            pairXAUT_USDC = factoryContract.createPair(xaut, usdc);
            console.log("  Created XAUT/USDC pair:", pairXAUT_USDC);
        } else {
            console.log("  XAUT/USDC pair exists:", pairXAUT_USDC);
        }
        console.log("");

        // STEP 2: Register pair addresses in IdentityRegistry
        console.log("STEP 2: Registering pairs in IdentityRegistry...");
        IIdentityRegistry registry = IIdentityRegistry(identityRegistry);
        
        if (!registry.isVerified(pairIDRX_USDC)) {
            registry.registerIdentity(pairIDRX_USDC);
            console.log("  Registered IDRX/USDC pair");
        } else {
            console.log("  IDRX/USDC pair already registered");
        }
        
        if (!registry.isVerified(pairXAUT_USDC)) {
            registry.registerIdentity(pairXAUT_USDC);
            console.log("  Registered XAUT/USDC pair");
        } else {
            console.log("  XAUT/USDC pair already registered");
        }
        console.log("");

        // STEP 3: Mint tokens with correct amounts
        console.log("STEP 3: Minting tokens...");
        uint256 idxAmount = 1_000_000_000 * 10**6;   // 1B IDRX
        uint256 usdcAmount = 1_000_000 * 10**6;      // 1M USDC
        uint256 xautAmount = 2_500 * 10**6;          // 2,500 XAUT
        
        IMintable(idrx).mint(deployer, idxAmount);
        console.log("  Minted 1,000,000,000 IDRX");
        
        IMintable(usdc).mint(deployer, usdcAmount);
        console.log("  Minted 1,000,000 USDC");
        
        IMintable(xaut).mint(deployer, xautAmount);
        console.log("  Minted 2,500 XAUT");
        console.log("");

        // STEP 4: Approve tokens
        console.log("STEP 4: Approving tokens...");
        IERC20(idrx).approve(router, type(uint256).max);
        IERC20(usdc).approve(router, type(uint256).max);
        IERC20(xaut).approve(router, type(uint256).max);
        console.log("  All tokens approved");
        console.log("");

        // STEP 5: Add IDRX/USDC liquidity
        // Ratio: 1 USDC = 16,500 IDRX
        // Using 60,606 USDC and 1,000,000,000 IDRX
        console.log("STEP 5: Adding IDRX/USDC liquidity...");
        console.log("  Target ratio: 1 USDC = 16,500 IDRX");
        
        uint256 idxLiq = 1_000_000_000 * 10**6;      // 1B IDRX
        uint256 usdcLiq1 = 60_606 * 10**6;           // ~60,606 USDC (1B / 16,500)
        
        console.log("  Adding", idxLiq / 10**6, "IDRX");
        console.log("  Adding", usdcLiq1 / 10**6, "USDC");
        
        IUniswapV2Router02(router).addLiquidity(
            idrx,
            usdc,
            idxLiq,
            usdcLiq1,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        console.log("  IDRX/USDC liquidity added successfully");
        console.log("");

        // STEP 6: Add XAUT/USDC liquidity
        // Ratio: 1 XAUT = 4,000 USDC
        // Using remaining USDC and all XAUT
        console.log("STEP 6: Adding XAUT/USDC liquidity...");
        console.log("  Target ratio: 1 XAUT = 4,000 USDC");
        
        uint256 xautLiq = 2_500 * 10**6;             // 2,500 XAUT
        uint256 usdcLiq2 = 10_000_000 * 10**6;       // 10M USDC (2,500 * 4,000)
        
        // Mint additional USDC if needed
        uint256 remainingUSDC = usdcAmount - usdcLiq1;
        if (remainingUSDC < usdcLiq2) {
            uint256 additionalUSDC = usdcLiq2 - remainingUSDC;
            IMintable(usdc).mint(deployer, additionalUSDC);
            console.log("  Minted additional", additionalUSDC / 10**6, "USDC");
            IERC20(usdc).approve(router, type(uint256).max);
        }
        
        console.log("  Adding", xautLiq / 10**6, "XAUT");
        console.log("  Adding", usdcLiq2 / 10**6, "USDC");
        
        IUniswapV2Router02(router).addLiquidity(
            xaut,
            usdc,
            xautLiq,
            usdcLiq2,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        console.log("  XAUT/USDC liquidity added successfully");
        console.log("");

        vm.stopBroadcast();

        console.log("==============================================");
        console.log("LIQUIDITY SETUP COMPLETED SUCCESSFULLY");
        console.log("==============================================");
        console.log("IDRX/USDC Pair:", pairIDRX_USDC);
        console.log("XAUT/USDC Pair:", pairXAUT_USDC);
        console.log("");
        console.log("Liquidity Ratios:");
        console.log("  1 USDC = 16,500 IDRX");
        console.log("  1 XAUT = 4,000 USDC");
        console.log("");
        console.log("Add to .env:");
        console.log("PAIR_IDRX_USDC=", pairIDRX_USDC);
        console.log("PAIR_XAUT_USDC=", pairXAUT_USDC);
        console.log("==============================================");
    }
}
