// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract AddXAUTUSDCLiquidity is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        address xaut = vm.envAddress("XAUT");
        address usdc = vm.envAddress("MOCK_USDC");
        address router = vm.envAddress("UNISWAP_ROUTER");
        
        // Use the existing pair address from first deployment
        address pairXAUT_USDC = 0xBdfD81D4e79c0cC949BB52941BCd30Ed8b3B4112;
        
        console.log("Adding XAUT/USDC liquidity...");
        console.log("XAUT:", xaut);
        console.log("USDC:", usdc);
        console.log("Router:", router);
        console.log("Pair:", pairXAUT_USDC);
        
        vm.startBroadcast(deployerPrivateKey);
        
        uint256 xautLiq = 100 * 10**6;         // 100 XAUT
        uint256 usdcLiq = 270_000 * 10**6;     // 270K USDC
        
        // Approve if needed
        IERC20(xaut).approve(router, xautLiq);
        IERC20(usdc).approve(router, usdcLiq);
        
        IUniswapV2Router02(router).addLiquidity(
            xaut,
            usdc,
            xautLiq,
            usdcLiq,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        
        vm.stopBroadcast();
        
        console.log("XAUT/USDC liquidity added successfully!");
    }
}
