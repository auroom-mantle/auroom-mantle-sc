#!/bin/bash

# Simulate deposit and borrow on Mantle Sepolia
# Usage: ./simulate-borrow.sh [collateral_xaut] [borrow_idrx]
# Example: ./simulate-borrow.sh 10 40000000  # 10 XAUT, 40M IDRX

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

if [ -z "$BORROWING_PROTOCOL_V2" ]; then
    echo "Error: BORROWING_PROTOCOL_V2 not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

# Parse arguments
COLLATERAL=${1:-10}     # Default: 10 XAUT
BORROW=${2:-40000000}   # Default: 40M IDRX

# Convert to wei (6 decimals)
COLLATERAL_WEI=$(echo "$COLLATERAL * 1000000" | bc)
BORROW_WEI=$(echo "$BORROW * 1000000" | bc)

USER=$(cast wallet address --private-key $PRIVATE_KEY)

echo "=============================================="
echo "Simulate Deposit and Borrow on Mantle Sepolia"
echo "=============================================="
echo "User: $USER"
echo "Collateral: $COLLATERAL XAUT"
echo "Borrow: $BORROW IDRX"
echo ""

# Check KYC
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $USER --rpc-url $MANTLE_SEPOLIA_RPC)
if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    echo "Error: User is not KYC verified!"
    echo "Run: ./register-kyc.sh"
    exit 1
fi
echo "KYC Status: Verified ✓"

# Check XAUT balance
XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)" $USER --rpc-url $MANTLE_SEPOLIA_RPC)
echo "XAUT Balance: $(echo "scale=6; $XAUT_BALANCE / 1000000" | bc) XAUT"

if [ "$XAUT_BALANCE" -lt "$COLLATERAL_WEI" ]; then
    echo "Error: Insufficient XAUT balance!"
    exit 1
fi

# Preview transaction
echo ""
echo "Previewing transaction..."
PREVIEW=$(cast call $BORROWING_PROTOCOL_V2 \
    "previewDepositAndBorrow(address,uint256,uint256)" \
    $USER $COLLATERAL_WEI $BORROW_WEI \
    --rpc-url $MANTLE_SEPOLIA_RPC)

echo "Preview result: $PREVIEW"

# Parse preview (amountReceived, fee, newLTV, allowed)
# Note: This is simplified, actual parsing depends on output format

echo ""
echo "Proceed with actual transaction? (y/n)"
read -r CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Cancelled."
    exit 0
fi

# Approve XAUT
echo "Approving XAUT..."
cast send $XAUT \
    "approve(address,uint256)" \
    $BORROWING_PROTOCOL_V2 \
    $COLLATERAL_WEI \
    --rpc-url $MANTLE_SEPOLIA_RPC \
    --private-key $PRIVATE_KEY \
    --quiet

# Execute depositAndBorrow
echo "Executing depositAndBorrow..."
cast send $BORROWING_PROTOCOL_V2 \
    "depositAndBorrow(uint256,uint256)" \
    $COLLATERAL_WEI \
    $BORROW_WEI \
    --rpc-url $MANTLE_SEPOLIA_RPC \
    --private-key $PRIVATE_KEY

echo ""
echo "Transaction complete!"
echo ""

# Show new position
echo "New position:"
./script/mantle/helper/check-balances.sh $USER
