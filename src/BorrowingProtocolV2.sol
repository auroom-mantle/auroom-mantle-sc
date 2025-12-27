// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IIdentityRegistry
 * @notice Interface for identity verification
 */
interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
}

/**
 * @title BorrowingProtocolV2
 * @notice Allows users to deposit XAUT as collateral and borrow IDRX against it
 * @dev Part of AuRoom Pay - borrowing protocol for AuRoom Protocol
 * 
 * V2 Changes:
 * - Added depositAndBorrow(): Deposit XAUT and borrow IDRX in single TX
 * - Added repayAndWithdraw(): Repay IDRX and withdraw XAUT in single TX
 * - Added closePosition(): Repay all debt and withdraw all collateral
 * - Added preview functions for new operations
 */
contract BorrowingProtocolV2 is ReentrancyGuard {
    
    // ============ State Variables ============
    
    /// @notice XAUT token (collateral)
    IERC20 public immutable xaut;
    
    /// @notice IDRX token (borrow token)
    IERC20 public immutable idrx;
    
    /// @notice Identity Registry for compliance checks
    IIdentityRegistry public immutable identityRegistry;
    
    /// @notice Treasury address (receives borrowed IDRX and fees)
    address public treasury;
    
    /// @notice User's XAUT collateral balance
    mapping(address => uint256) public collateralBalance;
    
    /// @notice User's IDRX debt balance
    mapping(address => uint256) public debtBalance;
    
    /// @notice XAUT price in IDRX with 8 decimals
    /// @dev Example: 1 XAUT = 42,660,000 IDRX → store as 4266000000000000 (8 decimals)
    uint256 public xautPriceInIDRX;
    
    /// @notice Timestamp of last price update
    uint256 public lastPriceUpdate;
    
    /// @notice Admin address
    address public admin;
    
    // ============ Constants ============
    
    /// @notice Maximum loan-to-value ratio (75%)
    uint256 public constant MAX_LTV = 7500;
    
    /// @notice Warning threshold for LTV (80%)
    uint256 public constant WARNING_LTV = 8000;
    
    /// @notice Liquidation threshold for LTV (90%)
    uint256 public constant LIQUIDATION_LTV = 9000;
    
    /// @notice Basis points denominator (100%)
    uint256 public constant BPS_DENOMINATOR = 10000;
    
    /// @notice Maximum borrow fee (5%)
    uint256 public constant MAX_BORROW_FEE = 500;
    
    /// @notice Price decimals (8 decimals for precision)
    uint256 public constant PRICE_DECIMALS = 1e8;
    
    /// @notice Borrow fee in basis points (default 0.5%)
    uint256 public borrowFeeBps = 50;
    
    // ============ Events ============
    
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 fee);
    event Repaid(address indexed user, uint256 amount);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    event LTVWarning(address indexed user, uint256 currentLTV);
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event BorrowFeeUpdated(uint256 oldFee, uint256 newFee);
    event AdminTransferred(address oldAdmin, address newAdmin);
    
    // V2 Events
    event DepositAndBorrow(address indexed user, uint256 collateralAmount, uint256 borrowAmount, uint256 fee);
    event RepayAndWithdraw(address indexed user, uint256 repayAmount, uint256 withdrawAmount);
    
    // ============ Modifiers ============
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    modifier onlyVerified() {
        require(identityRegistry.isVerified(msg.sender), "Not verified");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @notice Initialize the BorrowingProtocol
     * @param _xaut XAUT token address
     * @param _idrx IDRX token address
     * @param _identityRegistry Identity Registry address
     * @param _treasury Treasury address
     * @param _initialXAUTPrice Initial XAUT price in IDRX with 8 decimals
     */
    constructor(
        address _xaut,
        address _idrx,
        address _identityRegistry,
        address _treasury,
        uint256 _initialXAUTPrice
    ) {
        require(_xaut != address(0), "Invalid XAUT address");
        require(_idrx != address(0), "Invalid IDRX address");
        require(_identityRegistry != address(0), "Invalid registry address");
        require(_treasury != address(0), "Invalid treasury address");
        require(_initialXAUTPrice > 0, "Invalid initial price");
        
        xaut = IERC20(_xaut);
        idrx = IERC20(_idrx);
        identityRegistry = IIdentityRegistry(_identityRegistry);
        treasury = _treasury;
        admin = msg.sender;
        xautPriceInIDRX = _initialXAUTPrice;
        lastPriceUpdate = block.timestamp;
        
        emit PriceUpdated(0, _initialXAUTPrice, block.timestamp);
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Deposit XAUT as collateral
     * @param amount Amount of XAUT to deposit
     */
    function depositCollateral(uint256 amount) external onlyVerified nonReentrant {
        require(amount > 0, "Amount must be > 0");
        
        // Transfer XAUT from user to contract
        require(xaut.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update collateral balance
        collateralBalance[msg.sender] += amount;
        
        emit CollateralDeposited(msg.sender, amount);
    }
    
    /**
     * @notice Withdraw XAUT collateral
     * @param amount Amount of XAUT to withdraw
     */
    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(amount <= collateralBalance[msg.sender], "Insufficient collateral");
        
        // Calculate new LTV after withdrawal
        uint256 newCollateral = collateralBalance[msg.sender] - amount;
        uint256 debt = debtBalance[msg.sender];
        
        if (debt > 0) {
            // Calculate collateral value after withdrawal
            uint256 newCollateralValue = (newCollateral * xautPriceInIDRX) / PRICE_DECIMALS;
            require(newCollateralValue > 0, "Insufficient collateral value");
            
            // Calculate new LTV
            uint256 newLTV = (debt * BPS_DENOMINATOR) / newCollateralValue;
            require(newLTV <= MAX_LTV, "LTV exceeds maximum");
        }
        
        // Update collateral balance
        collateralBalance[msg.sender] = newCollateral;
        
        // Transfer XAUT back to user
        require(xaut.transfer(msg.sender, amount), "Transfer failed");
        
        emit CollateralWithdrawn(msg.sender, amount);
    }
    
    /**
     * @notice Borrow IDRX against collateral
     * @param amount Amount of IDRX to borrow
     */
    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(collateralBalance[msg.sender] > 0, "No collateral");
        
        // Calculate fee
        uint256 fee = (amount * borrowFeeBps) / BPS_DENOMINATOR;
        uint256 amountToReceive = amount - fee;
        
        // Calculate new total debt
        uint256 newDebt = debtBalance[msg.sender] + amount;
        
        // Calculate collateral value
        uint256 collateralValue = getCollateralValue(msg.sender);
        require(collateralValue > 0, "No collateral value");
        
        // Calculate new LTV
        uint256 newLTV = (newDebt * BPS_DENOMINATOR) / collateralValue;
        require(newLTV <= MAX_LTV, "LTV exceeds maximum");
        
        // Update debt balance (includes fee as debt)
        debtBalance[msg.sender] = newDebt;
        
        // Transfer IDRX to user (amount minus fee)
        require(idrx.transferFrom(treasury, msg.sender, amountToReceive), "Transfer failed");
        
        emit Borrowed(msg.sender, amount, fee);
        
        // Emit warning if LTV is high
        if (newLTV > WARNING_LTV) {
            emit LTVWarning(msg.sender, newLTV);
        }
    }
    
    /**
     * @notice Repay IDRX debt
     * @param amount Amount of IDRX to repay
     */
    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(amount <= debtBalance[msg.sender], "Amount exceeds debt");
        
        // Transfer IDRX from user to treasury
        require(idrx.transferFrom(msg.sender, treasury, amount), "Transfer failed");
        
        // Update debt balance
        debtBalance[msg.sender] -= amount;
        
        emit Repaid(msg.sender, amount);
    }
    
    /**
     * @notice Repay full debt
     */
    function repayFull() external nonReentrant {
        uint256 debt = debtBalance[msg.sender];
        require(debt > 0, "No debt to repay");
        
        // Transfer IDRX from user to treasury
        require(idrx.transferFrom(msg.sender, treasury, debt), "Transfer failed");
        
        // Update debt balance
        debtBalance[msg.sender] = 0;
        
        emit Repaid(msg.sender, debt);
    }
    
    // ============ V2: One-Click Functions ============
    
    /**
     * @notice Deposit XAUT and borrow IDRX in a single transaction
     * @dev Requires prior XAUT approval to this contract
     * @param collateralAmount Amount of XAUT to deposit (6 decimals)
     * @param borrowAmount Amount of IDRX to borrow (6 decimals)
     */
    function depositAndBorrow(
        uint256 collateralAmount,
        uint256 borrowAmount
    ) external onlyVerified nonReentrant {
        require(collateralAmount > 0, "Collateral must be > 0");
        require(borrowAmount > 0, "Borrow amount must be > 0");
        
        // 1. Transfer XAUT from user to contract
        require(xaut.transferFrom(msg.sender, address(this), collateralAmount), "XAUT transfer failed");
        
        // 2. Update collateral balance
        collateralBalance[msg.sender] += collateralAmount;
        
        // 3. Calculate fee
        uint256 fee = (borrowAmount * borrowFeeBps) / BPS_DENOMINATOR;
        uint256 amountToReceive = borrowAmount - fee;
        
        // 4. Calculate new total debt
        uint256 newDebt = debtBalance[msg.sender] + borrowAmount;
        
        // 5. Calculate collateral value (after deposit)
        uint256 collateralValue = getCollateralValue(msg.sender);
        require(collateralValue > 0, "No collateral value");
        
        // 6. Calculate new LTV
        uint256 newLTV = (newDebt * BPS_DENOMINATOR) / collateralValue;
        require(newLTV <= MAX_LTV, "LTV exceeds maximum");
        
        // 7. Update debt balance
        debtBalance[msg.sender] = newDebt;
        
        // 8. Transfer IDRX to user (amount minus fee)
        require(idrx.transferFrom(treasury, msg.sender, amountToReceive), "IDRX transfer failed");
        
        emit DepositAndBorrow(msg.sender, collateralAmount, borrowAmount, fee);
        
        // Emit warning if LTV is high
        if (newLTV > WARNING_LTV) {
            emit LTVWarning(msg.sender, newLTV);
        }
    }
    
    /**
     * @notice Repay IDRX debt and withdraw XAUT collateral in a single transaction
     * @dev Requires prior IDRX approval to this contract for repayment
     * @param repayAmount Amount of IDRX to repay (6 decimals), can be 0
     * @param withdrawAmount Amount of XAUT to withdraw (6 decimals), can be 0
     */
    function repayAndWithdraw(
        uint256 repayAmount,
        uint256 withdrawAmount
    ) external nonReentrant {
        require(repayAmount > 0 || withdrawAmount > 0, "Both amounts cannot be zero");
        
        // Validate amounts
        if (repayAmount > 0) {
            require(repayAmount <= debtBalance[msg.sender], "Repay amount exceeds debt");
        }
        if (withdrawAmount > 0) {
            require(withdrawAmount <= collateralBalance[msg.sender], "Withdraw amount exceeds collateral");
        }
        
        // 1. Repay debt first (if any)
        if (repayAmount > 0) {
            require(idrx.transferFrom(msg.sender, treasury, repayAmount), "IDRX transfer failed");
            debtBalance[msg.sender] -= repayAmount;
            emit Repaid(msg.sender, repayAmount);
        }
        
        // 2. Check and execute withdrawal (if any)
        if (withdrawAmount > 0) {
            uint256 newCollateral = collateralBalance[msg.sender] - withdrawAmount;
            uint256 remainingDebt = debtBalance[msg.sender];
            
            // Check LTV if there's remaining debt
            if (remainingDebt > 0) {
                uint256 newCollateralValue = (newCollateral * xautPriceInIDRX) / PRICE_DECIMALS;
                require(newCollateralValue > 0, "Insufficient collateral value");
                
                uint256 newLTV = (remainingDebt * BPS_DENOMINATOR) / newCollateralValue;
                require(newLTV <= MAX_LTV, "LTV exceeds maximum");
            }
            
            // Execute withdrawal
            collateralBalance[msg.sender] = newCollateral;
            require(xaut.transfer(msg.sender, withdrawAmount), "XAUT transfer failed");
            emit CollateralWithdrawn(msg.sender, withdrawAmount);
        }
        
        emit RepayAndWithdraw(msg.sender, repayAmount, withdrawAmount);
    }
    
    /**
     * @notice Close entire position: repay all debt and withdraw all collateral
     * @dev Convenience function to exit position completely in one transaction
     */
    function closePosition() external nonReentrant {
        uint256 debt = debtBalance[msg.sender];
        uint256 collateral = collateralBalance[msg.sender];
        
        require(collateral > 0, "No position to close");
        
        // 1. Repay all debt (if any)
        if (debt > 0) {
            require(idrx.transferFrom(msg.sender, treasury, debt), "IDRX transfer failed");
            debtBalance[msg.sender] = 0;
            emit Repaid(msg.sender, debt);
        }
        
        // 2. Withdraw all collateral
        collateralBalance[msg.sender] = 0;
        require(xaut.transfer(msg.sender, collateral), "XAUT transfer failed");
        emit CollateralWithdrawn(msg.sender, collateral);
        
        emit RepayAndWithdraw(msg.sender, debt, collateral);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get user's collateral balance
     * @param user User address
     * @return User's XAUT collateral balance
     */
    function getCollateral(address user) external view returns (uint256) {
        return collateralBalance[user];
    }
    
    /**
     * @notice Get user's debt balance
     * @param user User address
     * @return User's IDRX debt balance
     */
    function getDebt(address user) external view returns (uint256) {
        return debtBalance[user];
    }
    
    /**
     * @notice Get collateral value in IDRX terms
     * @param user User address
     * @return Collateral value in IDRX
     */
    function getCollateralValue(address user) public view returns (uint256) {
        return (collateralBalance[user] * xautPriceInIDRX) / PRICE_DECIMALS;
    }
    
    /**
     * @notice Calculate current LTV
     * @param user User address
     * @return LTV in basis points (0 if no collateral)
     */
    function getLTV(address user) public view returns (uint256) {
        uint256 collateralValue = getCollateralValue(user);
        if (collateralValue == 0) return 0;
        
        return (debtBalance[user] * BPS_DENOMINATOR) / collateralValue;
    }
    
    /**
     * @notice Get maximum additional IDRX user can borrow
     * @param user User address
     * @return Maximum borrowable amount
     */
    function getMaxBorrow(address user) external view returns (uint256) {
        uint256 collateralValue = getCollateralValue(user);
        if (collateralValue == 0) return 0;
        
        // Maximum total debt at MAX_LTV
        uint256 maxTotalDebt = (collateralValue * MAX_LTV) / BPS_DENOMINATOR;
        
        // Current debt
        uint256 currentDebt = debtBalance[user];
        
        // If already at or over max, can't borrow more
        if (currentDebt >= maxTotalDebt) return 0;
        
        return maxTotalDebt - currentDebt;
    }
    
    /**
     * @notice Get health factor (100 = at MAX_LTV, higher = healthier)
     * @param user User address
     * @return Health factor (0 if no debt)
     */
    function getHealthFactor(address user) external view returns (uint256) {
        uint256 debt = debtBalance[user];
        if (debt == 0) return type(uint256).max; // No debt = perfect health
        
        uint256 collateralValue = getCollateralValue(user);
        if (collateralValue == 0) return 0; // No collateral with debt = critical
        
        // Health factor = (collateralValue * MAX_LTV) / (debt * BPS_DENOMINATOR) * 100
        // Simplified: (collateralValue * MAX_LTV * 100) / (debt * BPS_DENOMINATOR)
        return (collateralValue * MAX_LTV * 100) / (debt * BPS_DENOMINATOR);
    }
    
    /**
     * @notice Check if position is at risk (LTV > WARNING_LTV)
     * @param user User address
     * @return True if at risk
     */
    function isAtRisk(address user) external view returns (bool) {
        uint256 ltv = getLTV(user);
        return ltv > WARNING_LTV;
    }
    
    /**
     * @notice Preview borrow operation
     * @param user User address
     * @param amount Amount to borrow
     * @return amountReceived Amount user will receive after fee
     * @return fee Borrow fee
     * @return newLTV New LTV after borrow
     */
    function previewBorrow(address user, uint256 amount) 
        external 
        view 
        returns (uint256 amountReceived, uint256 fee, uint256 newLTV) 
    {
        fee = (amount * borrowFeeBps) / BPS_DENOMINATOR;
        amountReceived = amount - fee;
        
        uint256 newDebt = debtBalance[user] + amount;
        uint256 collateralValue = getCollateralValue(user);
        
        if (collateralValue == 0) {
            newLTV = 0;
        } else {
            newLTV = (newDebt * BPS_DENOMINATOR) / collateralValue;
        }
    }
    
    /**
     * @notice Preview withdraw operation
     * @param user User address
     * @param amount Amount to withdraw
     * @return success Whether withdrawal would succeed
     * @return newLTV New LTV after withdrawal
     */
    function previewWithdraw(address user, uint256 amount)
        external
        view
        returns (bool success, uint256 newLTV)
    {
        if (amount > collateralBalance[user]) {
            return (false, 0);
        }
        
        uint256 newCollateral = collateralBalance[user] - amount;
        uint256 debt = debtBalance[user];
        
        if (debt == 0) {
            return (true, 0);
        }
        
        uint256 newCollateralValue = (newCollateral * xautPriceInIDRX) / PRICE_DECIMALS;
        
        if (newCollateralValue == 0) {
            return (false, 0);
        }
        
        newLTV = (debt * BPS_DENOMINATOR) / newCollateralValue;
        success = newLTV <= MAX_LTV;
    }
    
    // ============ V2: Preview Functions for New Operations ============
    
    /**
     * @notice Preview depositAndBorrow operation
     * @param user User address
     * @param collateralAmount Amount of XAUT to deposit
     * @param borrowAmount Amount of IDRX to borrow
     * @return amountReceived Amount user will receive after fee
     * @return fee Fee amount
     * @return newLTV New LTV after operation
     * @return allowed Whether operation is allowed (LTV <= MAX_LTV)
     */
    function previewDepositAndBorrow(
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount
    ) external view returns (
        uint256 amountReceived,
        uint256 fee,
        uint256 newLTV,
        bool allowed
    ) {
        fee = (borrowAmount * borrowFeeBps) / BPS_DENOMINATOR;
        amountReceived = borrowAmount - fee;
        
        // Calculate new collateral value (current + deposit)
        uint256 newCollateral = collateralBalance[user] + collateralAmount;
        uint256 newCollateralValue = (newCollateral * xautPriceInIDRX) / PRICE_DECIMALS;
        
        // Calculate new debt
        uint256 newDebt = debtBalance[user] + borrowAmount;
        
        if (newCollateralValue == 0) {
            newLTV = 0;
            allowed = false;
        } else {
            newLTV = (newDebt * BPS_DENOMINATOR) / newCollateralValue;
            allowed = newLTV <= MAX_LTV;
        }
    }
    
    /**
     * @notice Preview repayAndWithdraw operation
     * @param user User address
     * @param repayAmount Amount of IDRX to repay
     * @param withdrawAmount Amount of XAUT to withdraw
     * @return success Whether operation is allowed
     * @return newLTV New LTV after operation
     */
    function previewRepayAndWithdraw(
        address user,
        uint256 repayAmount,
        uint256 withdrawAmount
    ) external view returns (bool success, uint256 newLTV) {
        // Validate amounts
        if (repayAmount > debtBalance[user]) {
            return (false, 0);
        }
        if (withdrawAmount > collateralBalance[user]) {
            return (false, 0);
        }
        
        uint256 newDebt = debtBalance[user] - repayAmount;
        uint256 newCollateral = collateralBalance[user] - withdrawAmount;
        
        // If no remaining debt, any withdrawal is allowed
        if (newDebt == 0) {
            return (true, 0);
        }
        
        // If withdrawing all collateral but still have debt, not allowed
        if (newCollateral == 0) {
            return (false, 0);
        }
        
        uint256 newCollateralValue = (newCollateral * xautPriceInIDRX) / PRICE_DECIMALS;
        newLTV = (newDebt * BPS_DENOMINATOR) / newCollateralValue;
        success = newLTV <= MAX_LTV;
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Update XAUT price
     * @param newPrice New XAUT price in IDRX with 8 decimals
     */
    function setXAUTPrice(uint256 newPrice) external onlyAdmin {
        require(newPrice > 0, "Invalid price");
        
        uint256 oldPrice = xautPriceInIDRX;
        xautPriceInIDRX = newPrice;
        lastPriceUpdate = block.timestamp;
        
        emit PriceUpdated(oldPrice, newPrice, block.timestamp);
    }
    
    /**
     * @notice Update treasury address
     * @param newTreasury New treasury address
     */
    function setTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Invalid treasury address");
        
        address oldTreasury = treasury;
        treasury = newTreasury;
        
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }
    
    /**
     * @notice Update borrow fee
     * @param newFeeBps New borrow fee in basis points (max 5%)
     */
    function setBorrowFee(uint256 newFeeBps) external onlyAdmin {
        require(newFeeBps <= MAX_BORROW_FEE, "Fee exceeds maximum");
        
        uint256 oldFee = borrowFeeBps;
        borrowFeeBps = newFeeBps;
        
        emit BorrowFeeUpdated(oldFee, newFeeBps);
    }
    
    /**
     * @notice Transfer admin role
     * @param newAdmin New admin address
     */
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        
        address oldAdmin = admin;
        admin = newAdmin;
        
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}
