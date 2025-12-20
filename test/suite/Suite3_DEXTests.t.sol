// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ========================================
// INTERFACES
// ========================================

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IIdentityRegistry {
    function registerIdentity(address user) external;
    function isVerified(address user) external view returns (bool);
}

interface IMockToken {
    function publicMint(address to, uint256 amount) external;
}

/**
 * @title Suite3_DEXTests
 * @notice Test Suite 3: DEX Tests - UniswapV2 Pools & Swaps
 * @dev Tests interact with deployed Uniswap V2 contracts on Mantle Sepolia testnet
 * @dev Covers: Factory, Pool reserves, Quotes, Swaps
 */
contract Suite3_DEXTests is Test {
    // ========================================
    // DEPLOYED CONTRACT ADDRESSES
    // ========================================

    address constant MOCK_IDRX = 0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05;
    address constant MOCK_USDC = 0x96ABff3a2668B811371d7d763f06B3832CEdf38d;
    address constant XAUT_TOKEN = 0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78;
    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant UNISWAP_FACTORY = 0x8950d0D71a23085C514350df2682c3f6F1D7aBFE;
    address constant UNISWAP_ROUTER = 0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9;
    address constant IDRX_USDC_PAIR = 0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2;
    address constant XAUT_USDC_PAIR = 0xc2da5178F53f45f604A275a3934979944eB15602;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;

    // Network Configuration
    uint256 constant MANTLE_SEPOLIA_CHAIN_ID = 5003;
    string constant MANTLE_SEPOLIA_RPC = "https://rpc.sepolia.mantle.xyz";

    // ========================================
    // STATE VARIABLES
    // ========================================

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    IUniswapV2Pair public idrxUsdcPair;
    IUniswapV2Pair public xautUsdcPair;
    IERC20 public idrx;
    IERC20 public usdc;
    IERC20 public xaut;
    IIdentityRegistry public identityRegistry;

    address public trader;
    address public verifiedTrader;

    // ========================================
    // SETUP
    // ========================================

    function setUp() public {
        // Fork Mantle Sepolia
        vm.createSelectFork(MANTLE_SEPOLIA_RPC);

        // Verify we're on correct chain
        require(block.chainid == MANTLE_SEPOLIA_CHAIN_ID, "Wrong chain ID");

        // Initialize contracts
        factory = IUniswapV2Factory(UNISWAP_FACTORY);
        router = IUniswapV2Router02(UNISWAP_ROUTER);
        idrxUsdcPair = IUniswapV2Pair(IDRX_USDC_PAIR);
        xautUsdcPair = IUniswapV2Pair(XAUT_USDC_PAIR);
        idrx = IERC20(MOCK_IDRX);
        usdc = IERC20(MOCK_USDC);
        xaut = IERC20(XAUT_TOKEN);
        identityRegistry = IIdentityRegistry(IDENTITY_REGISTRY);

        // Create test addresses
        trader = makeAddr("trader");
        verifiedTrader = makeAddr("verifiedTrader");

        // Fund traders with MNT
        vm.deal(trader, 1 ether);
        vm.deal(verifiedTrader, 1 ether);

        // Verify the verifiedTrader in identity registry
        vm.prank(DEPLOYER);
        identityRegistry.registerIdentity(verifiedTrader);

        console.log("=== Suite 3: DEX Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Factory:", UNISWAP_FACTORY);
        console.log("Router:", UNISWAP_ROUTER);
        console.log("IDRX/USDC Pair:", IDRX_USDC_PAIR);
        console.log("XAUT/USDC Pair:", XAUT_USDC_PAIR);
        console.log("Trader:", trader);
        console.log("Verified Trader:", verifiedTrader);
        console.log("Verified Trader Status:", identityRegistry.isVerified(verifiedTrader));
    }

    // ========================================
    // SUITE 3.1: FACTORY TESTS
    // ========================================

    function test_Factory_GetPair_IDRX_USDC() public view {
        address pair = factory.getPair(MOCK_IDRX, MOCK_USDC);

        assertEq(pair, IDRX_USDC_PAIR, "IDRX/USDC pair address should match");
        assertTrue(pair != address(0), "Pair should exist");

        console.log("=== Test: Factory GetPair IDRX/USDC ===");
        console.log("Expected Pair:", IDRX_USDC_PAIR);
        console.log("Actual Pair:", pair);
        console.log("Match:", pair == IDRX_USDC_PAIR);
    }

    function test_Factory_GetPair_XAUT_USDC() public view {
        address pair = factory.getPair(XAUT_TOKEN, MOCK_USDC);

        assertEq(pair, XAUT_USDC_PAIR, "XAUT/USDC pair address should match");
        assertTrue(pair != address(0), "Pair should exist");

        console.log("=== Test: Factory GetPair XAUT/USDC ===");
        console.log("Expected Pair:", XAUT_USDC_PAIR);
        console.log("Actual Pair:", pair);
        console.log("Match:", pair == XAUT_USDC_PAIR);
    }

    function test_Factory_GetPair_ReverseOrder() public view {
        // Test that getPair works regardless of token order
        address pair1 = factory.getPair(MOCK_IDRX, MOCK_USDC);
        address pair2 = factory.getPair(MOCK_USDC, MOCK_IDRX);

        assertEq(pair1, pair2, "Pair should be same regardless of token order");

        console.log("=== Test: Factory GetPair Reverse Order ===");
        console.log("getPair(IDRX, USDC):", pair1);
        console.log("getPair(USDC, IDRX):", pair2);
        console.log("Same:", pair1 == pair2);
    }

    function test_Factory_AllPairsLength() public view {
        uint256 pairsLength = factory.allPairsLength();

        assertTrue(pairsLength >= 2, "Should have at least 2 pairs");

        console.log("=== Test: Factory AllPairsLength ===");
        console.log("Total Pairs:", pairsLength);
        console.log("Expected: >= 2");
    }

    // ========================================
    // SUITE 3.2: POOL RESERVES TESTS
    // ========================================

    function test_IDRX_USDC_Reserves() public view {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = idrxUsdcPair.getReserves();

        address token0 = idrxUsdcPair.token0();
        address token1 = idrxUsdcPair.token1();

        console.log("=== Test: IDRX/USDC Reserves ===");
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        console.log("Last Update:", blockTimestampLast);

        // Note: Pools may not have liquidity yet in testnet
        if (reserve0 == 0 && reserve1 == 0) {
            console.log("WARNING: Pool has no liquidity yet");
        } else {
            assertTrue(reserve0 > 0, "Reserve0 should be greater than 0");
            assertTrue(reserve1 > 0, "Reserve1 should be greater than 0");
        }
    }

    function test_XAUT_USDC_Reserves() public view {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = xautUsdcPair.getReserves();

        address token0 = xautUsdcPair.token0();
        address token1 = xautUsdcPair.token1();

        console.log("=== Test: XAUT/USDC Reserves ===");
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        console.log("Last Update:", blockTimestampLast);

        // Note: Pools may not have liquidity yet in testnet
        if (reserve0 == 0 && reserve1 == 0) {
            console.log("WARNING: Pool has no liquidity yet");
        } else {
            assertTrue(reserve0 > 0, "Reserve0 should be greater than 0");
            assertTrue(reserve1 > 0, "Reserve1 should be greater than 0");
        }
    }

    function test_Reserves_TokenOrdering() public view {
        // Verify token ordering in pair
        address token0_idrx = idrxUsdcPair.token0();
        address token1_idrx = idrxUsdcPair.token1();

        // One should be IDRX, one should be USDC
        assertTrue(
            (token0_idrx == MOCK_IDRX && token1_idrx == MOCK_USDC)
                || (token0_idrx == MOCK_USDC && token1_idrx == MOCK_IDRX),
            "Tokens should be IDRX and USDC"
        );

        console.log("=== Test: Token Ordering ===");
        console.log("IDRX/USDC Pair:");
        console.log("  Token0:", token0_idrx);
        console.log("  Token1:", token1_idrx);

        // Check token ordering is consistent (lower address is token0)
        if (MOCK_IDRX < MOCK_USDC) {
            assertEq(token0_idrx, MOCK_IDRX, "IDRX should be token0");
            assertEq(token1_idrx, MOCK_USDC, "USDC should be token1");
        } else {
            assertEq(token0_idrx, MOCK_USDC, "USDC should be token0");
            assertEq(token1_idrx, MOCK_IDRX, "IDRX should be token1");
        }
    }

    // ========================================
    // SUITE 3.3: QUOTE TESTS
    // ========================================

    function test_GetAmountsOut_IDRX_to_USDC() public view {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = idrxUsdcPair.getReserves();

        console.log("=== Test: GetAmountsOut IDRX to USDC ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 IDRX (6 decimals)

        address[] memory path = new address[](2);
        path[0] = MOCK_IDRX;
        path[1] = MOCK_USDC;

        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        assertEq(amounts.length, 2, "Should return 2 amounts");
        assertEq(amounts[0], amountIn, "First amount should be input amount");
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");

        console.log("Input (IDRX):", amounts[0]);
        console.log("Output (USDC):", amounts[1]);
        console.log("Exchange Rate:", (amounts[1] * 1e18) / amounts[0]);
    }

    function test_GetAmountsOut_USDC_to_IDRX() public view {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = idrxUsdcPair.getReserves();

        console.log("=== Test: GetAmountsOut USDC to IDRX ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 USDC (6 decimals)

        address[] memory path = new address[](2);
        path[0] = MOCK_USDC;
        path[1] = MOCK_IDRX;

        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        assertEq(amounts.length, 2, "Should return 2 amounts");
        assertEq(amounts[0], amountIn, "First amount should be input amount");
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");

        console.log("Input (USDC):", amounts[0]);
        console.log("Output (IDRX):", amounts[1]);
    }

    function test_GetAmountsOut_USDC_to_XAUT() public view {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = xautUsdcPair.getReserves();

        console.log("=== Test: GetAmountsOut USDC to XAUT ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 USDC

        address[] memory path = new address[](2);
        path[0] = MOCK_USDC;
        path[1] = XAUT_TOKEN;

        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        assertEq(amounts.length, 2, "Should return 2 amounts");
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");

        console.log("Input (USDC):", amounts[0]);
        console.log("Output (XAUT):", amounts[1]);
    }

    function test_GetAmountsOut_MultiHop_IDRX_USDC_XAUT() public view {
        // Check if pools have liquidity
        (uint112 reserve0_idrx, uint112 reserve1_idrx,) = idrxUsdcPair.getReserves();
        (uint112 reserve0_xaut, uint112 reserve1_xaut,) = xautUsdcPair.getReserves();

        console.log("=== Test: GetAmountsOut Multi-Hop IDRX->USDC->XAUT ===");

        if (reserve0_idrx == 0 || reserve1_idrx == 0 || reserve0_xaut == 0 || reserve1_xaut == 0) {
            console.log("SKIPPED: One or more pools have no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 IDRX

        // Multi-hop: IDRX -> USDC -> XAUT
        address[] memory path = new address[](3);
        path[0] = MOCK_IDRX;
        path[1] = MOCK_USDC;
        path[2] = XAUT_TOKEN;

        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        assertEq(amounts.length, 3, "Should return 3 amounts for 2-hop swap");
        assertEq(amounts[0], amountIn, "First amount should be input amount");
        assertTrue(amounts[1] > 0, "Intermediate amount should be greater than 0");
        assertTrue(amounts[2] > 0, "Final output should be greater than 0");

        console.log("Input (IDRX):", amounts[0]);
        console.log("Intermediate (USDC):", amounts[1]);
        console.log("Output (XAUT):", amounts[2]);
    }

    // ========================================
    // SUITE 3.4: SWAP TESTS
    // ========================================

    function test_Swap_IDRX_to_USDC() public {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = idrxUsdcPair.getReserves();

        console.log("=== Test: Swap IDRX to USDC ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 IDRX

        // Mint IDRX to trader
        vm.prank(trader);
        IMockToken(MOCK_IDRX).publicMint(trader, amountIn);

        // Get expected output
        address[] memory path = new address[](2);
        path[0] = MOCK_IDRX;
        path[1] = MOCK_USDC;

        uint256[] memory expectedAmounts = router.getAmountsOut(amountIn, path);
        uint256 expectedOutput = expectedAmounts[1];

        // Approve router
        vm.prank(trader);
        idrx.approve(UNISWAP_ROUTER, amountIn);

        // Execute swap
        vm.startPrank(trader);

        uint256 usdcBalanceBefore = usdc.balanceOf(trader);

        uint256[] memory amounts =
            router.swapExactTokensForTokens(amountIn, expectedOutput * 99 / 100, path, trader, block.timestamp + 1);

        uint256 usdcBalanceAfter = usdc.balanceOf(trader);

        vm.stopPrank();

        // Verify swap results
        assertEq(amounts[0], amountIn, "Input amount should match");
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");
        assertEq(usdcBalanceAfter - usdcBalanceBefore, amounts[1], "USDC balance should increase by output amount");

        console.log("Input (IDRX):", amounts[0]);
        console.log("Output (USDC):", amounts[1]);
        console.log("Expected Output:", expectedOutput);
        console.log("USDC Balance Before:", usdcBalanceBefore);
        console.log("USDC Balance After:", usdcBalanceAfter);
    }

    function test_Swap_USDC_to_XAUT_RequiresVerification() public {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = xautUsdcPair.getReserves();

        console.log("=== Test: Swap USDC to XAUT (Verified User) ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 USDC

        // Mint USDC to verifiedTrader
        vm.prank(verifiedTrader);
        IMockToken(MOCK_USDC).publicMint(verifiedTrader, amountIn);

        // Get expected output
        address[] memory path = new address[](2);
        path[0] = MOCK_USDC;
        path[1] = XAUT_TOKEN;

        uint256[] memory expectedAmounts = router.getAmountsOut(amountIn, path);
        uint256 expectedOutput = expectedAmounts[1];

        // Approve router
        vm.prank(verifiedTrader);
        usdc.approve(UNISWAP_ROUTER, amountIn);

        // Execute swap
        vm.startPrank(verifiedTrader);

        uint256 xautBalanceBefore = xaut.balanceOf(verifiedTrader);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn, expectedOutput * 99 / 100, path, verifiedTrader, block.timestamp + 1
        );

        uint256 xautBalanceAfter = xaut.balanceOf(verifiedTrader);

        vm.stopPrank();

        // Verify swap results
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");
        assertEq(xautBalanceAfter - xautBalanceBefore, amounts[1], "XAUT balance should increase by output amount");

        console.log("Input (USDC):", amounts[0]);
        console.log("Output (XAUT):", amounts[1]);
        console.log("Trader Verified:", identityRegistry.isVerified(verifiedTrader));
    }

    function test_Swap_SlippageProtection() public {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = idrxUsdcPair.getReserves();

        console.log("=== Test: Swap Slippage Protection ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 IDRX

        // Mint IDRX to trader
        vm.prank(trader);
        IMockToken(MOCK_IDRX).publicMint(trader, amountIn);

        // Get expected output
        address[] memory path = new address[](2);
        path[0] = MOCK_IDRX;
        path[1] = MOCK_USDC;

        uint256[] memory expectedAmounts = router.getAmountsOut(amountIn, path);
        uint256 expectedOutput = expectedAmounts[1];

        // Set unrealistic minimum output (higher than possible)
        uint256 unrealisticMinOut = expectedOutput * 2; // 200% of expected

        // Approve router
        vm.prank(trader);
        idrx.approve(UNISWAP_ROUTER, amountIn);

        // Execute swap - should revert
        vm.startPrank(trader);

        vm.expectRevert(); // UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT
        router.swapExactTokensForTokens(amountIn, unrealisticMinOut, path, trader, block.timestamp + 1);

        console.log("Expected Output:", expectedOutput);
        console.log("Unrealistic Min Out:", unrealisticMinOut);
        console.log("Swap correctly reverted due to slippage protection");

        vm.stopPrank();
    }

    function test_Swap_DeadlineProtection() public {
        // Check if pool has liquidity
        (uint112 reserve0, uint112 reserve1,) = idrxUsdcPair.getReserves();

        console.log("=== Test: Swap Deadline Protection ===");

        if (reserve0 == 0 || reserve1 == 0) {
            console.log("SKIPPED: Pool has no liquidity");
            return;
        }

        uint256 amountIn = 1000 * 10 ** 6; // 1000 IDRX

        // Mint IDRX to trader
        vm.prank(trader);
        IMockToken(MOCK_IDRX).publicMint(trader, amountIn);

        address[] memory path = new address[](2);
        path[0] = MOCK_IDRX;
        path[1] = MOCK_USDC;

        // Approve router
        vm.prank(trader);
        idrx.approve(UNISWAP_ROUTER, amountIn);

        // Use past deadline
        uint256 pastDeadline = block.timestamp - 1;

        // Execute swap - should revert
        vm.startPrank(trader);

        vm.expectRevert(); // UniswapV2: EXPIRED
        router.swapExactTokensForTokens(amountIn, 0, path, trader, pastDeadline);

        console.log("Current Time:", block.timestamp);
        console.log("Deadline:", pastDeadline);
        console.log("Swap correctly reverted due to expired deadline");

        vm.stopPrank();
    }
}
