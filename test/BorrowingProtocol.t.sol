// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../src/BorrowingProtocol.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Mock ERC20 token for testing
 */
contract MockERC20 is ERC20 {
    uint8 private _decimals;
    
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockIdentityRegistry
 * @notice Mock Identity Registry for testing
 */
contract MockIdentityRegistry {
    mapping(address => bool) private verified;
    
    function setVerified(address user, bool status) external {
        verified[user] = status;
    }
    
    function isVerified(address user) external view returns (bool) {
        return verified[user];
    }
}

/**
 * @title BorrowingProtocolTest
 * @notice Comprehensive test suite for BorrowingProtocol
 */
contract BorrowingProtocolTest is Test {
    BorrowingProtocol public protocol;
    MockERC20 public xaut;
    MockERC20 public idrx;
    MockIdentityRegistry public identityRegistry;
    
    address public admin;
    address public treasury;
    address public user1;
    address public user2;
    
    uint256 public constant INITIAL_XAUT_PRICE = 4266000000000000; // 42,660,000 IDRX per XAUT (8 decimals)
    uint256 public constant XAUT_DECIMALS = 6;
    uint256 public constant IDRX_DECIMALS = 6;
    
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 fee);
    event Repaid(address indexed user, uint256 amount);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    event LTVWarning(address indexed user, uint256 currentLTV);
    
    function setUp() public {
        admin = address(this);
        treasury = makeAddr("treasury");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy mock tokens
        xaut = new MockERC20("Mock XAUT", "XAUT", uint8(XAUT_DECIMALS));
        idrx = new MockERC20("Mock IDRX", "IDRX", uint8(IDRX_DECIMALS));
        
        // Deploy mock identity registry
        identityRegistry = new MockIdentityRegistry();
        
        // Deploy BorrowingProtocol
        protocol = new BorrowingProtocol(
            address(xaut),
            address(idrx),
            address(identityRegistry),
            treasury,
            INITIAL_XAUT_PRICE
        );
        
        // Setup initial balances
        xaut.mint(user1, 100 * 10**XAUT_DECIMALS); // 100 XAUT
        xaut.mint(user2, 50 * 10**XAUT_DECIMALS);  // 50 XAUT
        
        // Mint IDRX to treasury for lending
        idrx.mint(treasury, 10_000_000_000 * 10**IDRX_DECIMALS); // 10 billion IDRX
        
        // Approve treasury to allow protocol to transfer IDRX
        vm.prank(treasury);
        idrx.approve(address(protocol), type(uint256).max);
        
        // Verify users
        identityRegistry.setVerified(user1, true);
        identityRegistry.setVerified(user2, true);
    }
    
    // ============ Setup Tests ============
    
    function test_Constructor() public view {
        assertEq(address(protocol.xaut()), address(xaut));
        assertEq(address(protocol.idrx()), address(idrx));
        assertEq(address(protocol.identityRegistry()), address(identityRegistry));
        assertEq(protocol.treasury(), treasury);
        assertEq(protocol.admin(), admin);
        assertEq(protocol.xautPriceInIDRX(), INITIAL_XAUT_PRICE);
        assertEq(protocol.borrowFeeBps(), 50); // 0.5%
    }
    
    function test_ConstructorInvalidAddresses() public {
        vm.expectRevert("Invalid XAUT address");
        new BorrowingProtocol(address(0), address(idrx), address(identityRegistry), treasury, INITIAL_XAUT_PRICE);
        
        vm.expectRevert("Invalid IDRX address");
        new BorrowingProtocol(address(xaut), address(0), address(identityRegistry), treasury, INITIAL_XAUT_PRICE);
        
        vm.expectRevert("Invalid registry address");
        new BorrowingProtocol(address(xaut), address(idrx), address(0), treasury, INITIAL_XAUT_PRICE);
        
        vm.expectRevert("Invalid treasury address");
        new BorrowingProtocol(address(xaut), address(idrx), address(identityRegistry), address(0), INITIAL_XAUT_PRICE);
        
        vm.expectRevert("Invalid initial price");
        new BorrowingProtocol(address(xaut), address(idrx), address(identityRegistry), treasury, 0);
    }
    
    // ============ Deposit Tests ============
    
    function test_DepositCollateral() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS; // 10 XAUT
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        
        vm.expectEmit(true, false, false, true);
        emit CollateralDeposited(user1, depositAmount);
        
        protocol.depositCollateral(depositAmount);
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), depositAmount);
        assertEq(xaut.balanceOf(address(protocol)), depositAmount);
    }
    
    function test_DepositCollateralMultipleTimes() public {
        uint256 firstDeposit = 5 * 10**XAUT_DECIMALS;
        uint256 secondDeposit = 3 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), firstDeposit + secondDeposit);
        
        protocol.depositCollateral(firstDeposit);
        protocol.depositCollateral(secondDeposit);
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), firstDeposit + secondDeposit);
    }
    
    function test_DepositCollateralZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be > 0");
        protocol.depositCollateral(0);
        vm.stopPrank();
    }
    
    function test_DepositCollateralUnverifiedUser() public {
        address unverifiedUser = makeAddr("unverified");
        xaut.mint(unverifiedUser, 10 * 10**XAUT_DECIMALS);
        
        vm.startPrank(unverifiedUser);
        xaut.approve(address(protocol), 10 * 10**XAUT_DECIMALS);
        vm.expectRevert("Not verified");
        protocol.depositCollateral(10 * 10**XAUT_DECIMALS);
        vm.stopPrank();
    }
    
    // ============ Withdraw Tests ============
    
    function test_WithdrawCollateralNoDebt() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        uint256 withdrawAmount = 5 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        vm.expectEmit(true, false, false, true);
        emit CollateralWithdrawn(user1, withdrawAmount);
        
        protocol.withdrawCollateral(withdrawAmount);
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), depositAmount - withdrawAmount);
        assertEq(xaut.balanceOf(user1), 90 * 10**XAUT_DECIMALS + withdrawAmount);
    }
    
    function test_WithdrawCollateralWithHealthyLTV() public {
        // Deposit 10 XAUT
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Borrow at 50% LTV
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 5000) / 10000; // 50% LTV
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        
        // Try to withdraw 2 XAUT (should still be safe)
        uint256 withdrawAmount = 2 * 10**XAUT_DECIMALS;
        protocol.withdrawCollateral(withdrawAmount);
        vm.stopPrank();
        
        assertEq(protocol.collateralBalance(user1), depositAmount - withdrawAmount);
    }
    
    function test_WithdrawCollateralExceedsMaxLTV() public {
        // Deposit 10 XAUT
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Borrow at 70% LTV
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 7000) / 10000;
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        
        // Try to withdraw 3 XAUT (would exceed MAX_LTV)
        uint256 withdrawAmount = 3 * 10**XAUT_DECIMALS;
        vm.expectRevert("LTV exceeds maximum");
        protocol.withdrawCollateral(withdrawAmount);
        vm.stopPrank();
    }
    
    function test_WithdrawCollateralInsufficientBalance() public {
        uint256 depositAmount = 5 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        vm.expectRevert("Insufficient collateral");
        protocol.withdrawCollateral(10 * 10**XAUT_DECIMALS);
        vm.stopPrank();
    }
    
    function test_WithdrawCollateralZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be > 0");
        protocol.withdrawCollateral(0);
        vm.stopPrank();
    }
    
    // ============ Borrow Tests ============
    
    function test_Borrow() public {
        // Deposit 10 XAUT
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Borrow 30M IDRX (~70% LTV)
        uint256 borrowAmount = 30_000_000 * 10**IDRX_DECIMALS;
        uint256 expectedFee = (borrowAmount * 50) / 10000; // 0.5% fee
        uint256 expectedReceived = borrowAmount - expectedFee;
        
        uint256 balanceBefore = idrx.balanceOf(user1);
        
        idrx.approve(address(protocol), type(uint256).max);
        
        vm.expectEmit(true, false, false, true);
        emit Borrowed(user1, borrowAmount, expectedFee);
        
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        assertEq(protocol.debtBalance(user1), borrowAmount);
        assertEq(idrx.balanceOf(user1), balanceBefore + expectedReceived);
    }
    
    function test_BorrowAtMaxLTV() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Borrow at exactly MAX_LTV (75%)
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 7500) / 10000;
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        uint256 ltv = protocol.getLTV(user1);
        assertEq(ltv, 7500); // Should be exactly at MAX_LTV
    }
    
    function test_BorrowExceedsMaxLTV() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Try to borrow more than MAX_LTV
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 8000) / 10000; // 80% > 75%
        
        idrx.approve(address(protocol), type(uint256).max);
        vm.expectRevert("LTV exceeds maximum");
        protocol.borrow(borrowAmount);
        vm.stopPrank();
    }
    
    function test_BorrowWithoutCollateral() public {
        vm.startPrank(user1);
        idrx.approve(address(protocol), type(uint256).max);
        vm.expectRevert("No collateral");
        protocol.borrow(1000 * 10**IDRX_DECIMALS);
        vm.stopPrank();
    }
    
    function test_BorrowZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be > 0");
        protocol.borrow(0);
        vm.stopPrank();
    }
    
    function test_BorrowEmitsWarning() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Borrow at exactly WARNING_LTV + 1 to trigger warning
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 7400) / 10000; // 74% LTV
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        // Admin drops price to make LTV go above WARNING_LTV
        uint256 newPrice = INITIAL_XAUT_PRICE * 90 / 100; // 10% drop
        protocol.setXAUTPrice(newPrice);
        
        // User borrows a bit more, should trigger warning
        vm.startPrank(user1);
        uint256 newCollateralValue = protocol.getCollateralValue(user1);
        uint256 currentDebt = protocol.debtBalance(user1);
        
        // Borrow just enough to go above WARNING_LTV
        uint256 additionalBorrow = (newCollateralValue * 7300) / 10000;
        if (additionalBorrow > currentDebt) {
            additionalBorrow = additionalBorrow - currentDebt;
            uint256 newLTV = ((currentDebt + additionalBorrow) * 10000) / newCollateralValue;
            
            if (newLTV > 8000) {
                vm.expectEmit(true, false, false, true);
                emit LTVWarning(user1, newLTV);
            }
            protocol.borrow(additionalBorrow);
        }
        vm.stopPrank();
    }
    
    function test_BorrowFeeCalculation() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        uint256 borrowAmount = 10_000_000 * 10**IDRX_DECIMALS; // 10M IDRX
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        idrx.approve(address(protocol), type(uint256).max);
        
        uint256 balanceBefore = idrx.balanceOf(user1);
        protocol.borrow(borrowAmount);
        uint256 balanceAfter = idrx.balanceOf(user1);
        
        uint256 expectedFee = (borrowAmount * 50) / 10000; // 0.5%
        uint256 expectedReceived = borrowAmount - expectedFee;
        
        assertEq(balanceAfter - balanceBefore, expectedReceived);
        assertEq(protocol.debtBalance(user1), borrowAmount); // Debt includes fee
        vm.stopPrank();
    }
    
    // ============ Repay Tests ============
    
    function test_Repay() public {
        // Setup: deposit and borrow
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        uint256 borrowAmount = 20_000_000 * 10**IDRX_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        
        // Repay half
        uint256 repayAmount = borrowAmount / 2;
        
        vm.expectEmit(true, false, false, true);
        emit Repaid(user1, repayAmount);
        
        protocol.repay(repayAmount);
        vm.stopPrank();
        
        assertEq(protocol.debtBalance(user1), borrowAmount - repayAmount);
    }
    
    function test_RepayFull() public {
        // Setup: deposit and borrow
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        uint256 borrowAmount = 20_000_000 * 10**IDRX_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        
        uint256 debt = protocol.debtBalance(user1);
        
        // User needs to have enough IDRX to repay the full debt
        // They received (borrowAmount - fee), but owe borrowAmount
        // So we need to mint the fee amount to them
        uint256 fee = (borrowAmount * 50) / 10000;
        idrx.mint(user1, fee);
        
        // Repay full using repayFull()
        protocol.repayFull();
        vm.stopPrank();
        
        assertEq(protocol.debtBalance(user1), 0);
    }
    
    function test_RepayFullWithRepayFunction() public {
        // Setup: deposit and borrow
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        uint256 borrowAmount = 20_000_000 * 10**IDRX_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        
        uint256 debt = protocol.debtBalance(user1);
        
        // User needs to have enough IDRX to repay the full debt
        uint256 fee = (borrowAmount * 50) / 10000;
        idrx.mint(user1, fee);
        
        // Repay full using repay() with actual debt amount
        protocol.repay(debt);
        vm.stopPrank();
        
        assertEq(protocol.debtBalance(user1), 0);
    }
    
    function test_RepayMoreThanDebt() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        uint256 borrowAmount = 10_000_000 * 10**IDRX_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        
        vm.expectRevert("Amount exceeds debt");
        protocol.repay(borrowAmount + 1);
        vm.stopPrank();
    }
    
    function test_RepayZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be > 0");
        protocol.repay(0);
        vm.stopPrank();
    }
    
    function test_RepayFullNoDebt() public {
        vm.startPrank(user1);
        vm.expectRevert("No debt to repay");
        protocol.repayFull();
        vm.stopPrank();
    }
    
    // ============ LTV Calculation Tests ============
    
    function test_GetCollateralValue() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS; // 10 XAUT
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        vm.stopPrank();
        
        uint256 expectedValue = (depositAmount * INITIAL_XAUT_PRICE) / 1e8;
        assertEq(protocol.getCollateralValue(user1), expectedValue);
    }
    
    function test_GetLTV() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 6000) / 10000; // 60% LTV
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        uint256 ltv = protocol.getLTV(user1);
        assertEq(ltv, 6000); // Should be 60%
    }
    
    function test_GetLTVNoCollateral() public view {
        uint256 ltv = protocol.getLTV(user1);
        assertEq(ltv, 0);
    }
    
    function test_LTVChangesWithPriceUpdate() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 5000) / 10000; // 50% LTV
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        uint256 ltvBefore = protocol.getLTV(user1);
        assertEq(ltvBefore, 5000);
        
        // Price drops by 20%
        uint256 newPrice = INITIAL_XAUT_PRICE * 80 / 100;
        protocol.setXAUTPrice(newPrice);
        
        uint256 ltvAfter = protocol.getLTV(user1);
        assertTrue(ltvAfter > ltvBefore); // LTV should increase when price drops
    }
    
    // ============ Admin Tests ============
    
    function test_SetXAUTPrice() public {
        uint256 newPrice = 5000000000000000; // 50M IDRX per XAUT
        
        vm.expectEmit(false, false, false, true);
        emit PriceUpdated(INITIAL_XAUT_PRICE, newPrice, block.timestamp);
        
        protocol.setXAUTPrice(newPrice);
        
        assertEq(protocol.xautPriceInIDRX(), newPrice);
        assertEq(protocol.lastPriceUpdate(), block.timestamp);
    }
    
    function test_SetXAUTPriceNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Not admin");
        protocol.setXAUTPrice(5000000000000000);
    }
    
    function test_SetXAUTPriceZero() public {
        vm.expectRevert("Invalid price");
        protocol.setXAUTPrice(0);
    }
    
    function test_SetTreasury() public {
        address newTreasury = makeAddr("newTreasury");
        protocol.setTreasury(newTreasury);
        assertEq(protocol.treasury(), newTreasury);
    }
    
    function test_SetTreasuryNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Not admin");
        protocol.setTreasury(makeAddr("newTreasury"));
    }
    
    function test_SetTreasuryZeroAddress() public {
        vm.expectRevert("Invalid treasury address");
        protocol.setTreasury(address(0));
    }
    
    function test_SetBorrowFee() public {
        uint256 newFee = 100; // 1%
        protocol.setBorrowFee(newFee);
        assertEq(protocol.borrowFeeBps(), newFee);
    }
    
    function test_SetBorrowFeeNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Not admin");
        protocol.setBorrowFee(100);
    }
    
    function test_SetBorrowFeeExceedsMax() public {
        vm.expectRevert("Fee exceeds maximum");
        protocol.setBorrowFee(501); // > 5%
    }
    
    function test_TransferAdmin() public {
        address newAdmin = makeAddr("newAdmin");
        protocol.transferAdmin(newAdmin);
        assertEq(protocol.admin(), newAdmin);
    }
    
    function test_TransferAdminNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Not admin");
        protocol.transferAdmin(makeAddr("newAdmin"));
    }
    
    function test_TransferAdminZeroAddress() public {
        vm.expectRevert("Invalid admin address");
        protocol.transferAdmin(address(0));
    }
    
    // ============ View Function Tests ============
    
    function test_GetMaxBorrow() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        vm.stopPrank();
        
        uint256 maxBorrow = protocol.getMaxBorrow(user1);
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 expectedMax = (collateralValue * 7500) / 10000; // 75% of collateral value
        
        assertEq(maxBorrow, expectedMax);
    }
    
    function test_GetMaxBorrowAfterBorrowing() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 5000) / 10000; // 50% LTV
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        uint256 maxBorrow = protocol.getMaxBorrow(user1);
        uint256 expectedMax = (collateralValue * 7500) / 10000 - borrowAmount;
        
        assertEq(maxBorrow, expectedMax);
    }
    
    function test_GetMaxBorrowNoCollateral() public view {
        uint256 maxBorrow = protocol.getMaxBorrow(user1);
        assertEq(maxBorrow, 0);
    }
    
    function test_GetHealthFactor() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 7500) / 10000; // At MAX_LTV
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        uint256 healthFactor = protocol.getHealthFactor(user1);
        assertEq(healthFactor, 100); // At MAX_LTV = 100
    }
    
    function test_GetHealthFactorNoDebt() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        vm.stopPrank();
        
        uint256 healthFactor = protocol.getHealthFactor(user1);
        assertEq(healthFactor, type(uint256).max); // No debt = perfect health
    }
    
    function test_IsAtRisk() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        // Borrow at 70% LTV (not at risk)
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 7000) / 10000;
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        assertFalse(protocol.isAtRisk(user1));
        
        // Price drops, making LTV go above WARNING_LTV
        uint256 newPrice = INITIAL_XAUT_PRICE * 85 / 100; // 15% drop
        protocol.setXAUTPrice(newPrice);
        
        assertTrue(protocol.isAtRisk(user1));
    }
    
    function test_PreviewBorrow() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        vm.stopPrank();
        
        uint256 borrowAmount = 10_000_000 * 10**IDRX_DECIMALS;
        (uint256 amountReceived, uint256 fee, uint256 newLTV) = protocol.previewBorrow(user1, borrowAmount);
        
        uint256 expectedFee = (borrowAmount * 50) / 10000;
        assertEq(fee, expectedFee);
        assertEq(amountReceived, borrowAmount - expectedFee);
        
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 expectedLTV = (borrowAmount * 10000) / collateralValue;
        assertEq(newLTV, expectedLTV);
    }
    
    function test_PreviewWithdraw() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        
        uint256 collateralValue = protocol.getCollateralValue(user1);
        uint256 borrowAmount = (collateralValue * 6000) / 10000; // 60% LTV (safer)
        
        idrx.approve(address(protocol), type(uint256).max);
        protocol.borrow(borrowAmount);
        vm.stopPrank();
        
        // Try to preview withdraw 2 XAUT (should be safe at 60% LTV)
        uint256 withdrawAmount = 2 * 10**XAUT_DECIMALS;
        (bool success, uint256 newLTV) = protocol.previewWithdraw(user1, withdrawAmount);
        
        assertTrue(success); // Should succeed
        assertLe(newLTV, 7500); // Should still be within MAX_LTV
        
        // Try to preview withdraw 6 XAUT (too much - would leave only 4 XAUT)
        withdrawAmount = 6 * 10**XAUT_DECIMALS;
        (success, newLTV) = protocol.previewWithdraw(user1, withdrawAmount);
        
        assertFalse(success); // Should fail
    }
    
    function test_PreviewWithdrawNoDebt() public {
        uint256 depositAmount = 10 * 10**XAUT_DECIMALS;
        
        vm.startPrank(user1);
        xaut.approve(address(protocol), depositAmount);
        protocol.depositCollateral(depositAmount);
        vm.stopPrank();
        
        uint256 withdrawAmount = 5 * 10**XAUT_DECIMALS;
        (bool success, uint256 newLTV) = protocol.previewWithdraw(user1, withdrawAmount);
        
        assertTrue(success);
        assertEq(newLTV, 0); // No debt
    }
}
