// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../src/interfaces/IUniswapV2Factory.sol";
import "../../../src/interfaces/IUniswapV2Router02.sol";

/**
 * @title Deploy07_SetupLiquidity
 * @notice Setup initial liquidity pools on Mantle Sepolia
 * @dev Creates IDRX/USDC and XAUT/USDC pairs with initial liquidity
 * 
 * Ratios:
 *   - 1 USDC = 16,500 IDRX
 *   - 1 XAUT = 4,000 USDC
 * 
 * Usage:
 *   forge script script/mantle/deployment/Deploy07_SetupLiquidity.s.sol \
 *     --rpc-url $MANTLE_SEPOLIA_RPC \
 *     --broadcast
 */
contract Deploy07_SetupLiquidity is Script {
    // Initial liquidity amounts
    uint256 constant IDRX_AMOUNT = 1_000_000_000 * 1e6;  // 1B IDRX
    uint256 constant USDC_FOR_IDRX = 60_606 * 1e6;       // ~60,606 USDC
    uint256 constant XAUT_AMOUNT = 2_500 * 1e6;          // 2,500 XAUT
    uint256 constant USDC_FOR_XAUT = 10_000_000 * 1e6;   // 10M USDC

    // Contract addresses (loaded from env)
    address idrx;
    address usdc;
    address xaut;
    address factory;
    address router;
    address identityRegistry;
    address deployer;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
        
        // Load addresses
        idrx = vm.envAddress("MOCK_IDRX");
        usdc = vm.envAddress("MOCK_USDC");
        xaut = vm.envAddress("XAUT");
        factory = vm.envAddress("UNISWAP_FACTORY");
        router = vm.envAddress("UNISWAP_ROUTER");
        identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        console.log("Deploy07: Setup Liquidity Pools");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Mint tokens
        _mintTokens();
        
        // 2. Approve router
        _approveRouter();
        
        // 3. Register router in KYC
        _registerRouter();
        
        // 4. Add IDRX/USDC liquidity
        address pair1 = _addIDRXUSDCLiquidity();
        
        // 5. Add XAUT/USDC liquidity
        address pair2 = _addXAUTUSDCLiquidity();
        
        vm.stopBroadcast();
        
        console.log("IDRX/USDC Pair:", pair1);
        console.log("XAUT/USDC Pair:", pair2);
        console.log("Setup complete!");
    }
    
    function _mintTokens() internal {
        (bool success,) = idrx.call(
            abi.encodeWithSignature("publicMint(address,uint256)", deployer, IDRX_AMOUNT)
        );
        require(success, "IDRX mint failed");
        
        (success,) = usdc.call(
            abi.encodeWithSignature("publicMint(address,uint256)", deployer, USDC_FOR_IDRX + USDC_FOR_XAUT)
        );
        require(success, "USDC mint failed");
        
        (success,) = xaut.call(
            abi.encodeWithSignature("mint(address,uint256)", deployer, XAUT_AMOUNT)
        );
        require(success, "XAUT mint failed");
    }
    
    function _approveRouter() internal {
        IERC20(idrx).approve(router, type(uint256).max);
        IERC20(usdc).approve(router, type(uint256).max);
        IERC20(xaut).approve(router, type(uint256).max);
    }
    
    function _registerRouter() internal {
        (bool success,) = identityRegistry.call(
            abi.encodeWithSignature("registerIdentity(address)", router)
        );
        require(success, "Router KYC failed");
    }
    
    function _addIDRXUSDCLiquidity() internal returns (address pair) {
        IUniswapV2Router02(router).addLiquidity(
            idrx, usdc, IDRX_AMOUNT, USDC_FOR_IDRX, 0, 0, deployer, block.timestamp + 3600
        );
        pair = IUniswapV2Factory(factory).getPair(idrx, usdc);
    }
    
    function _addXAUTUSDCLiquidity() internal returns (address pair) {
        // Create pair first
        pair = IUniswapV2Factory(factory).createPair(xaut, usdc);
        
        // Register pair in KYC
        (bool success,) = identityRegistry.call(
            abi.encodeWithSignature("registerIdentity(address)", pair)
        );
        require(success, "Pair KYC failed");
        
        // Add liquidity
        IUniswapV2Router02(router).addLiquidity(
            xaut, usdc, XAUT_AMOUNT, USDC_FOR_XAUT, 0, 0, deployer, block.timestamp + 3600
        );
    }
}
