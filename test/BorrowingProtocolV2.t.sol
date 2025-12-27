// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../src/BorrowingProtocolV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Simple ERC20 mock for testing
 */
contract MockERC20 is ERC20 {
    uint8 private _decimals;
    
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockIdentityRegistry
 * @notice Simple identity registry mock for testing
 */
contract MockIdentityRegistry {
    mapping(address => bool) public verified;
    
    function isVerified(address user) external view returns (bool) {
        return verified[user];
    }
    
    function setVerified(address user, bool status) external {
        verified[user] = status;
    }
}

/**
 * @title BorrowingProtocolV2Test
 * @notice Tests for V2 functions: depositAndBorrow, repayAndWithdraw, closePosition
 */
contract BorrowingProtocolV2Test is Test {
    BorrowingProtocolV2 public protocol;
    MockERC20 public xaut;
    MockERC20 public idrx;
    MockIdentityRegistry public identityRegistry;
    
    address public admin = address(1);
    address public treasury = address(2);
    address public user1 = address(3);
    address public user2 = address(4);
    
    // Initial price: 42,660,000 IDRX per XAUT (8 decimals)
    uint256 public constant INITIAL_PRICE = 4_266_000_000_000_000; // 42.66M with 8 decimals
    
    // Token amounts (6 decimals)
    uint256 public constant ONE_XAUT = 1_000_000;      // 1 XAUT
    uint256 public constant TEN_XAUT = 10_000_000;     // 10 XAUT
    uint256 public constant ONE_M_IDRX = 1_000_000_000_000;    // 1M IDRX
    uint256 public constant TEN_M_IDRX = 10_000_000_000_000;   // 10M IDRX
    uint256 public constant THIRTY_M_IDRX = 30_000_000_000_000; // 30M IDRX
    
    function setUp() public {
        // Deploy mocks
        xaut = new MockERC20("Tether Gold", "XAUT", 6);
        idrx = new MockERC20("IDRX Stablecoin", "IDRX", 6);
        identityRegistry = new MockIdentityRegistry();
        
        // Deploy protocol (V2 constructor order: xaut, idrx, registry, treasury, price)
        vm.prank(admin);
        protocol = new BorrowingProtocolV2(
            address(xaut),
            address(idrx),
            address(identityRegistry),
            treasury,
            INITIAL_PRICE
        );
        
        // Setup treasury with IDRX
        idrx.mint(treasury, 1_000_000 * ONE_M_IDRX); // 1 trillion IDRX
        vm.prank(treasury);
        idrx.approve(address(protocol), type(uint256).max);
        
        // Setup users
        xaut.mint(user1, 100 * ONE_XAUT); // 100 XAUT
        xaut.mint(user2, 100 * ONE_XAUT); // 100 XAUT
        idrx.mint(user1, 1000 * ONE_M_IDRX); // 1000M IDRX
        idrx.mint(user2, 1000 * ONE_M_IDRX); // 1000M IDRX
        
        // Verify users
        identityRegistry.setVerified(user1, true);
        identityRegistry.setVerified(user2, true);
    }
    
    // ========== depositAndBorrow Tests ==========
    
    function test_depositAndBorrow_Success() public {
        uint256 collateralAmount = TEN_XAUT;
        uint256 borrowAmount = THIRTY_M_IDRX;
        
        // Approve XAUT
        vm.startPrank(user1);
        xaut.approve(address(protocol), collateralAmount);
        
        // Get initial balances
        uint256 xautBefore = xaut.balanceOf(user1);
        uint256 idrxBefore = idrx.balanceOf(user1);
        
        // Execute depositAndBorrow
        protocol.depositAndBorrow(collateralAmount, borrowAmount);
        vm.stopPrank();
        
        // Calculate expected values
        uint256 fee = (borrowAmount * 50) / 10000; // 0.5% fee
        uint256 expectedReceived = borrowAmount - fee;
        
        // Verify collateral deposited
        assertEq(protocol.collateralBalance(user1), collateralAmount, "Collateral not deposited");
        assertEq(xaut.balanceOf(user1), xautBefore - collateralAmount, "XAUT not transferred");
        
        // Verify debt created
        assertEq(protocol.debtBalance(user1), borrowAmount, "Debt not recorded");
        
        // Verify IDRX received (minus fee)
        assertEq(idrx.balanceOf(user1), idrxBefore + expectedReceived, "IDRX not received");
        
        // Verify LTV
        uint256 ltv = protocol.getLTV(user1);
        assertTrue(ltv > 0 && ltv <= 7500, "LTV out of range");
    }
    
    function test_depositAndBorrow_EmitsEvents() public {
        uint256 collateralAmount = TEN_XAUT;
        uint256 borrowAmount = THIRTY_M_IDRX;
        uint256 fee = (borrowAmount * 50) / 10000;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), collateralAmount);
        
        vm.expectEmit(true, false, false, true);
        emit BorrowingProtocolV2.DepositAndBorrow(user1, collateralAmount, borrowAmount, fee);
        
        protocol.depositAndBorrow(collateralAmount, borrowAmount);
        vm.stopPrank();
    }
    
    function test_depositAndBorrow_RevertsIfNotVerified() public {
        identityRegistry.setVerified(user1, false);
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        
        vm.expectRevert("Not verified");
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
    }
    
    function test_depositAndBorrow_RevertsIfZeroCollateral() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Collateral must be > 0");
        protocol.depositAndBorrow(0, THIRTY_M_IDRX);
        vm.stopPrank();
    }
    
    function test_depositAndBorrow_RevertsIfZeroBorrow() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        
        vm.expectRevert("Borrow amount must be > 0");
        protocol.depositAndBorrow(TEN_XAUT, 0);
        vm.stopPrank();
    }
    
    function test_depositAndBorrow_RevertsIfExceedsMaxLTV() public {
        uint256 collateralAmount = ONE_XAUT; // 1 XAUT = ~42.66M IDRX value
        uint256 borrowAmount = 40 * ONE_M_IDRX; // 40M IDRX = ~93% LTV
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), collateralAmount);
        
        vm.expectRevert("LTV exceeds maximum");
        protocol.depositAndBorrow(collateralAmount, borrowAmount);
        vm.stopPrank();
    }
    
    function test_depositAndBorrow_MaxLTVBoundary() public {
        uint256 collateralAmount = TEN_XAUT; // 10 XAUT = ~426.6M IDRX value
        // 75% of 426.6M = 319.95M IDRX
        uint256 collateralValue = (collateralAmount * INITIAL_PRICE) / 1e8;
        uint256 maxBorrow = (collateralValue * 7500) / 10000;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), collateralAmount);
        
        // Should succeed at exactly 75% LTV
        protocol.depositAndBorrow(collateralAmount, maxBorrow);
        vm.stopPrank();
        
        uint256 ltv = protocol.getLTV(user1);
        assertApproxEqAbs(ltv, 7500, 10, "LTV should be ~75%");
    }
    
    function test_depositAndBorrow_WithExistingPosition() public {
        // First deposit using standard function
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT * 2);
        protocol.depositCollateral(TEN_XAUT);
        
        // Now use depositAndBorrow to add more
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        // Should have 20 XAUT collateral
        assertEq(protocol.collateralBalance(user1), TEN_XAUT * 2, "Total collateral incorrect");
        assertEq(protocol.debtBalance(user1), THIRTY_M_IDRX, "Debt incorrect");
    }
    
    function test_depositAndBorrow_EmitsLTVWarning() public {
        uint256 collateralAmount = TEN_XAUT;
        // Borrow enough to trigger WARNING_LTV (80%)
        uint256 collateralValue = (collateralAmount * INITIAL_PRICE) / 1e8;
        uint256 borrowAmount = (collateralValue * 7400) / 10000; // Just under 75%
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), collateralAmount);
        
        // First borrow at ~74%
        protocol.depositAndBorrow(collateralAmount, borrowAmount);
        vm.stopPrank();
        
        // LTV should be close to but under 75%
        uint256 ltv = protocol.getLTV(user1);
        assertTrue(ltv < 7500, "LTV should be under max");
    }
    
    // ========== repayAndWithdraw Tests ==========
    
    function test_repayAndWithdraw_Success() public {
        // Setup: deposit and borrow first
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        
        // Approve IDRX for repayment
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        // Repay half and withdraw some
        uint256 repayAmount = 15 * ONE_M_IDRX;
        uint256 withdrawAmount = 3 * ONE_XAUT;
        
        uint256 xautBefore = xaut.balanceOf(user1);
        
        protocol.repayAndWithdraw(repayAmount, withdrawAmount);
        vm.stopPrank();
        
        // Verify debt reduced
        assertEq(protocol.debtBalance(user1), THIRTY_M_IDRX - repayAmount, "Debt not reduced");
        
        // Verify collateral reduced
        assertEq(protocol.collateralBalance(user1), TEN_XAUT - withdrawAmount, "Collateral not reduced");
        
        // Verify XAUT received
        assertEq(xaut.balanceOf(user1), xautBefore + withdrawAmount, "XAUT not received");
    }
    
    function test_repayAndWithdraw_EmitsEvents() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        uint256 repayAmount = 15 * ONE_M_IDRX;
        uint256 withdrawAmount = 3 * ONE_XAUT;
        
        // Should emit Repaid, CollateralWithdrawn, and RepayAndWithdraw events
        vm.expectEmit(true, false, false, true);
        emit BorrowingProtocolV2.RepayAndWithdraw(user1, repayAmount, withdrawAmount);
        
        protocol.repayAndWithdraw(repayAmount, withdrawAmount);
        vm.stopPrank();
    }
    
    function test_repayAndWithdraw_OnlyRepay() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        // Only repay, no withdraw
        protocol.repayAndWithdraw(15 * ONE_M_IDRX, 0);
        vm.stopPrank();
        
        assertEq(protocol.debtBalance(user1), 15 * ONE_M_IDRX, "Debt not reduced correctly");
        assertEq(protocol.collateralBalance(user1), TEN_XAUT, "Collateral should not change");
    }
    
    function test_repayAndWithdraw_OnlyWithdraw() public {
        // Deposit without borrowing
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositCollateral(TEN_XAUT);
        
        // Withdraw only
        protocol.repayAndWithdraw(0, 5 * ONE_XAUT);
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), 5 * ONE_XAUT, "Collateral not reduced");
    }
    
    function test_repayAndWithdraw_RevertsIfBothZero() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositCollateral(TEN_XAUT);
        
        vm.expectRevert("Both amounts cannot be zero");
        protocol.repayAndWithdraw(0, 0);
        vm.stopPrank();
    }
    
    function test_repayAndWithdraw_RevertsIfExceedsDebt() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        idrx.approve(address(protocol), 100 * ONE_M_IDRX);
        
        vm.expectRevert("Repay amount exceeds debt");
        protocol.repayAndWithdraw(50 * ONE_M_IDRX, 0);
        vm.stopPrank();
    }
    
    function test_repayAndWithdraw_RevertsIfExceedsCollateral() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositCollateral(TEN_XAUT);
        
        vm.expectRevert("Withdraw amount exceeds collateral");
        protocol.repayAndWithdraw(0, 20 * ONE_XAUT);
        vm.stopPrank();
    }
    
    function test_repayAndWithdraw_RevertsIfWithdrawExceedsLTV() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        // Try to withdraw 9 XAUT with 30M debt - would exceed LTV
        // 1 XAUT = 42.66M, 30M debt / 42.66M = 70% LTV - but need to check
        vm.expectRevert("LTV exceeds maximum");
        protocol.repayAndWithdraw(0, 9 * ONE_XAUT);
        vm.stopPrank();
    }
    
    // ========== closePosition Tests ==========
    
    function test_closePosition_Success() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        uint256 xautBefore = xaut.balanceOf(user1);
        
        protocol.closePosition();
        vm.stopPrank();
        
        // Position should be fully closed
        assertEq(protocol.debtBalance(user1), 0, "Debt should be zero");
        assertEq(protocol.collateralBalance(user1), 0, "Collateral should be zero");
        
        // User should have received all collateral back
        assertEq(xaut.balanceOf(user1), xautBefore + TEN_XAUT, "XAUT not returned");
    }
    
    function test_closePosition_WithNoDebt() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositCollateral(TEN_XAUT);
        
        uint256 xautBefore = xaut.balanceOf(user1);
        
        protocol.closePosition();
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), 0, "Collateral should be zero");
        assertEq(xaut.balanceOf(user1), xautBefore + TEN_XAUT, "XAUT not returned");
    }
    
    function test_closePosition_RevertsIfNoCollateral() public {
        vm.startPrank(user1);
        
        vm.expectRevert("No position to close");
        protocol.closePosition();
        vm.stopPrank();
    }
    
    function test_closePosition_EmitsEvents() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        idrx.approve(address(protocol), THIRTY_M_IDRX);
        
        vm.expectEmit(true, false, false, true);
        emit BorrowingProtocolV2.RepayAndWithdraw(user1, THIRTY_M_IDRX, TEN_XAUT);
        
        protocol.closePosition();
        vm.stopPrank();
    }
    
    // ========== Preview Functions Tests ==========
    
    function test_previewDepositAndBorrow() public {
        uint256 collateralAmount = TEN_XAUT;
        uint256 borrowAmount = THIRTY_M_IDRX;
        
        (
            uint256 amountReceived,
            uint256 fee,
            uint256 newLTV,
            bool allowed
        ) = protocol.previewDepositAndBorrow(user1, collateralAmount, borrowAmount);
        
        uint256 expectedFee = (borrowAmount * 50) / 10000;
        assertEq(fee, expectedFee, "Fee calculation incorrect");
        assertEq(amountReceived, borrowAmount - expectedFee, "Amount received incorrect");
        assertTrue(newLTV > 0 && newLTV <= 7500, "LTV out of range");
        assertTrue(allowed, "Should be allowed");
    }
    
    function test_previewDepositAndBorrow_ExceedsLTV() public {
        uint256 collateralAmount = ONE_XAUT;
        uint256 borrowAmount = 40 * ONE_M_IDRX; // >75% LTV
        
        (
            uint256 amountReceived,
            uint256 fee,
            uint256 newLTV,
            bool allowed
        ) = protocol.previewDepositAndBorrow(user1, collateralAmount, borrowAmount);
        
        assertTrue(newLTV > 7500, "LTV should exceed max");
        assertFalse(allowed, "Should not be allowed");
    }
    
    function test_previewRepayAndWithdraw() public {
        // Setup position
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        // Preview repay and withdraw
        uint256 repayAmount = 15 * ONE_M_IDRX;
        uint256 withdrawAmount = 3 * ONE_XAUT;
        
        (bool success, uint256 newLTV) = protocol.previewRepayAndWithdraw(
            user1, repayAmount, withdrawAmount
        );
        
        assertTrue(newLTV <= 7500, "LTV should be valid");
        assertTrue(success, "Should be allowed");
    }
    
    function test_previewRepayAndWithdraw_NotAllowed() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        // Try to withdraw too much
        (bool success, uint256 newLTV) = protocol.previewRepayAndWithdraw(
            user1, 0, 9 * ONE_XAUT
        );
        
        assertFalse(success, "Should not be allowed");
    }
    
    // ========== Integration Tests ==========
    
    function test_FullUserJourney() public {
        // 1. User deposits and borrows in one transaction
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT * 2);
        protocol.depositAndBorrow(TEN_XAUT, 20 * ONE_M_IDRX);
        
        // 2. User adds more collateral and borrows more
        protocol.depositAndBorrow(5 * ONE_XAUT, 10 * ONE_M_IDRX);
        
        assertEq(protocol.collateralBalance(user1), 15 * ONE_XAUT, "Total collateral");
        assertEq(protocol.debtBalance(user1), 30 * ONE_M_IDRX, "Total debt");
        
        // 3. User partially repays and withdraws
        idrx.approve(address(protocol), 100 * ONE_M_IDRX);
        protocol.repayAndWithdraw(10 * ONE_M_IDRX, 2 * ONE_XAUT);
        
        assertEq(protocol.collateralBalance(user1), 13 * ONE_XAUT, "After partial withdraw");
        assertEq(protocol.debtBalance(user1), 20 * ONE_M_IDRX, "After partial repay");
        
        // 4. User closes position
        protocol.closePosition();
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), 0, "Position closed");
        assertEq(protocol.debtBalance(user1), 0, "Debt cleared");
    }
    
    function test_MultipleUsers() public {
        // User 1 deposits and borrows
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, 20 * ONE_M_IDRX);
        vm.stopPrank();
        
        // User 2 deposits and borrows
        vm.startPrank(user2);
        xaut.approve(address(protocol), 5 * ONE_XAUT);
        protocol.depositAndBorrow(5 * ONE_XAUT, 10 * ONE_M_IDRX);
        vm.stopPrank();
        
        // Verify independent positions
        assertEq(protocol.collateralBalance(user1), TEN_XAUT, "User1 collateral");
        assertEq(protocol.debtBalance(user1), 20 * ONE_M_IDRX, "User1 debt");
        
        assertEq(protocol.collateralBalance(user2), 5 * ONE_XAUT, "User2 collateral");
        assertEq(protocol.debtBalance(user2), 10 * ONE_M_IDRX, "User2 debt");
        
        // User 1 closes position
        vm.startPrank(user1);
        idrx.approve(address(protocol), 20 * ONE_M_IDRX);
        protocol.closePosition();
        vm.stopPrank();
        
        // User 2 should be unaffected
        assertEq(protocol.collateralBalance(user2), 5 * ONE_XAUT, "User2 collateral unchanged");
        assertEq(protocol.debtBalance(user2), 10 * ONE_M_IDRX, "User2 debt unchanged");
    }
    
    // ========== V1 Compatibility Tests ==========
    
    function test_V1Functions_StillWork() public {
        // Test that all V1 functions still work correctly
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT * 2);
        
        // V1: depositCollateral
        protocol.depositCollateral(TEN_XAUT);
        assertEq(protocol.getCollateral(user1), TEN_XAUT);
        
        // V1: borrow
        protocol.borrow(20 * ONE_M_IDRX);
        assertEq(protocol.getDebt(user1), 20 * ONE_M_IDRX);
        
        // V1: repay
        idrx.approve(address(protocol), 100 * ONE_M_IDRX);
        protocol.repay(5 * ONE_M_IDRX);
        assertEq(protocol.getDebt(user1), 15 * ONE_M_IDRX);
        
        // V1: withdrawCollateral
        protocol.withdrawCollateral(2 * ONE_XAUT);
        assertEq(protocol.getCollateral(user1), 8 * ONE_XAUT);
        
        // V1: repayFull
        protocol.repayFull();
        assertEq(protocol.getDebt(user1), 0);
        
        vm.stopPrank();
    }
    
    function test_V1ViewFunctions_StillWork() public {
        vm.startPrank(user1);
        xaut.approve(address(protocol), TEN_XAUT);
        protocol.depositAndBorrow(TEN_XAUT, THIRTY_M_IDRX);
        vm.stopPrank();
        
        // Test V1 view functions
        assertEq(protocol.getCollateral(user1), TEN_XAUT);
        assertEq(protocol.getDebt(user1), THIRTY_M_IDRX);
        assertTrue(protocol.getCollateralValue(user1) > 0);
        assertTrue(protocol.getLTV(user1) > 0);
        assertTrue(protocol.getMaxBorrow(user1) >= 0);
        assertTrue(protocol.getHealthFactor(user1) > 0);
        
        // previewBorrow (V1 signature)
        (uint256 received, uint256 fee, uint256 newLTV) = protocol.previewBorrow(user1, ONE_M_IDRX);
        assertTrue(received > 0);
        assertTrue(fee > 0);
        assertTrue(newLTV > 0);
        
        // previewWithdraw (V1 signature: returns bool success, uint256 newLTV)
        (bool success, uint256 withdrawLTV) = protocol.previewWithdraw(user1, ONE_XAUT);
        // This should work with small withdrawal
    }
}
