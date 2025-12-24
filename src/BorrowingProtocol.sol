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
 * @title BorrowingProtocol
 * @notice Allows users to deposit XAUT as collateral and borrow IDRX against it
 * @dev Part of AuRoom Pay - borrowing protocol for AuRoom Protocol
 */
contract BorrowingProtocol is ReentrancyGuard {
    
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
    function repayFull() external {
        uint256 debt = debtBalance[msg.sender];
        require(debt > 0, "No debt to repay");
        
        // Transfer IDRX from user to treasury
        require(idrx.transferFrom(msg.sender, treasury, debt), "Transfer failed");
        
        // Update debt balance
        debtBalance[msg.sender] = 0;
        
        emit Repaid(msg.sender, debt);
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
