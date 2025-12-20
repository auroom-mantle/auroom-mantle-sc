// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// ========================================
// INTERFACE
// ========================================

interface IIdentityRegistry {
    // Events
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event IdentityRemoved(address indexed user, uint256 timestamp);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    // Errors
    error NotAdmin();
    error ZeroAddress();
    error AlreadyVerified();
    error NotVerified();

    // Functions
    function registerIdentity(address user) external;
    function removeIdentity(address user) external;
    function batchRegisterIdentity(address[] calldata users) external;
    function isVerified(address user) external view returns (bool);
    function isAdmin(address account) external view returns (bool);
    function addAdmin(address admin) external;
    function removeAdmin(address admin) external;
    function owner() external view returns (address);
}

/**
 * @title Suite2_IdentityRegistryTests
 * @notice Test Suite 2: IdentityRegistry Tests - Registration, Access Control
 * @dev Tests interact with deployed IdentityRegistry on Mantle Sepolia testnet
 * @dev Covers: Admin management, Registration functions, Access control, Events
 */
contract Suite2_IdentityRegistryTests is Test {
    // ========================================
    // DEPLOYED CONTRACT ADDRESSES
    // ========================================

    address constant IDENTITY_REGISTRY = 0x620870d419F6aFca8AFed5B516619aa50900cadc;
    address constant DEPLOYER = 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1;

    // Network Configuration
    uint256 constant MANTLE_SEPOLIA_CHAIN_ID = 5003;
    string constant MANTLE_SEPOLIA_RPC = "https://rpc.sepolia.mantle.xyz";

    // ========================================
    // STATE VARIABLES
    // ========================================

    IIdentityRegistry public registry;

    address public newUser1;
    address public newUser2;
    address public newUser3;
    address public nonAdmin;
    address public newAdmin;

    // ========================================
    // SETUP
    // ========================================

    function setUp() public {
        // Fork Mantle Sepolia
        vm.createSelectFork(MANTLE_SEPOLIA_RPC);

        // Verify we're on correct chain
        require(block.chainid == MANTLE_SEPOLIA_CHAIN_ID, "Wrong chain ID");

        // Initialize registry
        registry = IIdentityRegistry(IDENTITY_REGISTRY);

        // Create test addresses
        newUser1 = makeAddr("newUser1");
        newUser2 = makeAddr("newUser2");
        newUser3 = makeAddr("newUser3");
        nonAdmin = makeAddr("nonAdmin");
        newAdmin = makeAddr("newAdmin");

        // Fund test accounts with MNT (native token)
        vm.deal(newUser1, 1 ether);
        vm.deal(newUser2, 1 ether);
        vm.deal(newUser3, 1 ether);
        vm.deal(nonAdmin, 1 ether);
        vm.deal(newAdmin, 1 ether);

        console.log("=== Suite 2: IdentityRegistry Test Setup ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Registry:", IDENTITY_REGISTRY);
        console.log("Deployer (Owner):", DEPLOYER);
        console.log("New User 1:", newUser1);
        console.log("New User 2:", newUser2);
        console.log("New User 3:", newUser3);
        console.log("Non Admin:", nonAdmin);
    }

    // ========================================
    // SUITE 2.1: ADMIN & ACCESS CONTROL TESTS
    // ========================================

    function test_Owner_IsAdmin() public view {
        // Owner should automatically be admin
        bool isOwnerAdmin = registry.isAdmin(DEPLOYER);
        address owner = registry.owner();

        assertEq(owner, DEPLOYER, "Owner address mismatch");
        assertTrue(isOwnerAdmin, "Owner should be admin");

        console.log("Owner:", owner);
        console.log("Owner is admin:", isOwnerAdmin);
    }

    function test_IsAdmin_ReturnsCorrect() public {
        // Test that isAdmin returns correct status for different addresses

        // DEPLOYER should be admin (owner)
        assertTrue(registry.isAdmin(DEPLOYER), "Deployer should be admin");

        // nonAdmin should NOT be admin
        assertFalse(registry.isAdmin(nonAdmin), "nonAdmin should not be admin");

        // Add newAdmin as admin
        vm.prank(DEPLOYER);
        registry.addAdmin(newAdmin);

        // newAdmin should now be admin
        assertTrue(registry.isAdmin(newAdmin), "newAdmin should be admin after being added");

        console.log("Deployer is admin:", registry.isAdmin(DEPLOYER));
        console.log("nonAdmin is admin:", registry.isAdmin(nonAdmin));
        console.log("newAdmin is admin (after adding):", registry.isAdmin(newAdmin));
    }

    function test_OnlyAdmin_CanRegister() public {
        // Non-admin should not be able to register identity

        vm.startPrank(nonAdmin);

        // Verify nonAdmin is not an admin
        assertFalse(registry.isAdmin(nonAdmin), "nonAdmin should not be admin");

        // Try to register - should revert
        vm.expectRevert(IIdentityRegistry.NotAdmin.selector);
        registry.registerIdentity(newUser1);

        console.log("Non-admin correctly prevented from registering");

        vm.stopPrank();
    }

    function test_OnlyOwner_CanAddAdmin() public {
        // Non-owner should not be able to add admin

        vm.startPrank(nonAdmin);

        // Try to add admin as non-owner - should revert with Ownable error
        vm.expectRevert();
        registry.addAdmin(newAdmin);

        console.log("Non-owner correctly prevented from adding admin");

        vm.stopPrank();

        // Owner can add admin
        vm.prank(DEPLOYER);
        registry.addAdmin(newAdmin);

        assertTrue(registry.isAdmin(newAdmin), "Owner should be able to add admin");

        console.log("Owner successfully added admin");
    }

    function test_AddAdmin_EmitsEvent() public {
        // Test that adding admin emits AdminAdded event

        vm.startPrank(DEPLOYER);

        vm.expectEmit(true, false, false, false);
        emit IIdentityRegistry.AdminAdded(newAdmin);

        registry.addAdmin(newAdmin);

        console.log("AdminAdded event emitted correctly");

        vm.stopPrank();
    }

    function test_RemoveAdmin_Success() public {
        // Add admin first
        vm.prank(DEPLOYER);
        registry.addAdmin(newAdmin);

        assertTrue(registry.isAdmin(newAdmin), "Admin should be added");

        // Remove admin
        vm.startPrank(DEPLOYER);

        vm.expectEmit(true, false, false, false);
        emit IIdentityRegistry.AdminRemoved(newAdmin);

        registry.removeAdmin(newAdmin);

        vm.stopPrank();

        assertFalse(registry.isAdmin(newAdmin), "Admin should be removed");

        console.log("Admin removed successfully");
    }

    // ========================================
    // SUITE 2.2: REGISTRATION FUNCTION TESTS
    // ========================================

    function test_RegisterIdentity_Success() public {
        // Admin can register new identity

        vm.startPrank(DEPLOYER);

        // Verify user is not registered initially
        assertFalse(registry.isVerified(newUser1), "User should not be verified initially");

        // Register identity
        registry.registerIdentity(newUser1);

        // Verify user is now registered
        assertTrue(registry.isVerified(newUser1), "User should be verified after registration");

        console.log("User1 verified status before:", false);
        console.log("User1 verified status after:", registry.isVerified(newUser1));

        vm.stopPrank();
    }

    function test_RegisterIdentity_CanRegisterTwice() public {
        // Test that registering same address twice doesn't cause issues (idempotent)

        vm.startPrank(DEPLOYER);

        // First registration
        registry.registerIdentity(newUser1);
        assertTrue(registry.isVerified(newUser1), "User should be verified after first registration");

        // Second registration of same address - should not revert
        registry.registerIdentity(newUser1);
        assertTrue(registry.isVerified(newUser1), "User should still be verified after second registration");

        console.log("Registering same address twice is idempotent");

        vm.stopPrank();
    }

    function test_RemoveIdentity_Success() public {
        // Admin can remove identity

        vm.startPrank(DEPLOYER);

        // Register first
        registry.registerIdentity(newUser1);
        assertTrue(registry.isVerified(newUser1), "User should be verified");

        // Remove identity
        registry.removeIdentity(newUser1);

        // Verify user is no longer registered
        assertFalse(registry.isVerified(newUser1), "User should not be verified after removal");

        console.log("User1 verified status before removal:", true);
        console.log("User1 verified status after removal:", registry.isVerified(newUser1));

        vm.stopPrank();
    }

    function test_BatchRegisterIdentity_Success() public {
        // Admin can batch register multiple addresses

        vm.startPrank(DEPLOYER);

        // Create array of users to register
        address[] memory users = new address[](3);
        users[0] = newUser1;
        users[1] = newUser2;
        users[2] = newUser3;

        // Verify none are registered initially
        assertFalse(registry.isVerified(newUser1), "User1 should not be verified initially");
        assertFalse(registry.isVerified(newUser2), "User2 should not be verified initially");
        assertFalse(registry.isVerified(newUser3), "User3 should not be verified initially");

        // Batch register
        registry.batchRegisterIdentity(users);

        // Verify all are now registered
        assertTrue(registry.isVerified(newUser1), "User1 should be verified");
        assertTrue(registry.isVerified(newUser2), "User2 should be verified");
        assertTrue(registry.isVerified(newUser3), "User3 should be verified");

        console.log("Batch registration successful:");
        console.log("  User1 verified:", registry.isVerified(newUser1));
        console.log("  User2 verified:", registry.isVerified(newUser2));
        console.log("  User3 verified:", registry.isVerified(newUser3));

        vm.stopPrank();
    }

    function test_IsVerified_ReturnsCorrect() public {
        // Test that isVerified returns correct status

        vm.startPrank(DEPLOYER);

        // Initially, newUser1 should not be verified
        assertFalse(registry.isVerified(newUser1), "User should not be verified initially");

        // Register newUser1
        registry.registerIdentity(newUser1);

        // Now newUser1 should be verified
        assertTrue(registry.isVerified(newUser1), "User should be verified after registration");

        // newUser2 should still not be verified
        assertFalse(registry.isVerified(newUser2), "User2 should not be verified");

        console.log("isVerified returns correct status for registered and unregistered users");

        vm.stopPrank();
    }

    function test_RegisterIdentity_RevertsOnZeroAddress() public {
        // Registering zero address should revert

        vm.startPrank(DEPLOYER);

        vm.expectRevert(IIdentityRegistry.ZeroAddress.selector);
        registry.registerIdentity(address(0));

        console.log("Zero address registration correctly reverted");

        vm.stopPrank();
    }

    function test_RemoveIdentity_RevertsOnZeroAddress() public {
        // Removing zero address should revert

        vm.startPrank(DEPLOYER);

        vm.expectRevert(IIdentityRegistry.ZeroAddress.selector);
        registry.removeIdentity(address(0));

        console.log("Zero address removal correctly reverted");

        vm.stopPrank();
    }

    // ========================================
    // SUITE 2.3: EVENT TESTS
    // ========================================

    function test_RegisterIdentity_EmitsEvent() public {
        // Should emit IdentityRegistered event with correct parameters

        vm.startPrank(DEPLOYER);

        // Expect event with user address and timestamp
        vm.expectEmit(true, false, false, false);
        emit IIdentityRegistry.IdentityRegistered(newUser1, block.timestamp);

        registry.registerIdentity(newUser1);

        console.log("IdentityRegistered event emitted correctly");
        console.log("  User:", newUser1);
        console.log("  Timestamp:", block.timestamp);

        vm.stopPrank();
    }

    function test_RemoveIdentity_EmitsEvent() public {
        // Should emit IdentityRemoved event with correct parameters

        vm.startPrank(DEPLOYER);

        // Register first
        registry.registerIdentity(newUser1);

        // Expect event with user address and timestamp
        vm.expectEmit(true, false, false, false);
        emit IIdentityRegistry.IdentityRemoved(newUser1, block.timestamp);

        registry.removeIdentity(newUser1);

        console.log("IdentityRemoved event emitted correctly");
        console.log("  User:", newUser1);
        console.log("  Timestamp:", block.timestamp);

        vm.stopPrank();
    }

    function test_BatchRegisterIdentity_EmitsEvents() public {
        // Batch register should emit event for each user

        vm.startPrank(DEPLOYER);

        address[] memory users = new address[](2);
        users[0] = newUser1;
        users[1] = newUser2;

        // Expect events for each user
        vm.expectEmit(true, false, false, false);
        emit IIdentityRegistry.IdentityRegistered(newUser1, block.timestamp);

        vm.expectEmit(true, false, false, false);
        emit IIdentityRegistry.IdentityRegistered(newUser2, block.timestamp);

        registry.batchRegisterIdentity(users);

        console.log("Batch registration emitted events for all users");

        vm.stopPrank();
    }
}
