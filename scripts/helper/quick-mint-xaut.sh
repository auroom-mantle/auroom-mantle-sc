#!/bin/bash

# Quick Mint XAUT Script (Owner-only)
# XAUT requires owner privileges and verified recipient
# Usage: ./quick-mint-xaut.sh [amount]
# Default: 100 XAUT

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Contract addresses
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Parse amount (default: 100 XAUT)
AMOUNT=${1:-100}

# Convert to raw amount (6 decimals)
RAW_AMOUNT=$(echo "$AMOUNT * 1000000" | bc | cut -d'.' -f1)

echo "========================================="
echo "🪙  Quick Mint: XAUT"
echo "========================================="
echo "Token: XAUT ($XAUT)"
echo "Recipient: $DEPLOYER"
echo "Amount: $AMOUNT XAUT"
echo "Raw Amount: $RAW_AMOUNT"
echo ""

# Check owner
echo "Checking XAUT owner..."
OWNER=$(cast call $XAUT "owner()(address)" --rpc-url $MANTLE_TESTNET_RPC)
echo "XAUT Owner: $OWNER"
echo "Your Address: $DEPLOYER"

if [ "$OWNER" != "$DEPLOYER" ]; then
    echo ""
    echo "⚠️  WARNING: You are not the owner of XAUT!"
    echo "   This transaction will likely fail."
    echo ""
fi

# Check if recipient is verified
echo ""
echo "Checking identity registry..."
IDENTITY_REGISTRY=$(cast call $XAUT "identityRegistry()(address)" --rpc-url $MANTLE_TESTNET_RPC)
echo "Identity Registry: $IDENTITY_REGISTRY"

IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)(bool)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC)
echo "Is Deployer Verified: $IS_VERIFIED"

if [ "$IS_VERIFIED" = "false" ]; then
    echo ""
    echo "❌ ERROR: Deployer is not verified in identity registry!"
    echo "   You need to verify the address first."
    echo ""
    echo "Run this command to verify:"
    echo "  cast send $IDENTITY_REGISTRY \"addIdentity(address)\" $DEPLOYER --rpc-url \$MANTLE_TESTNET_RPC --private-key \$PRIVATE_KEY --legacy"
    exit 1
fi

echo ""
echo "✅ All checks passed!"
echo ""

# Mint tokens (using owner-only mint function)
echo "🚀 Minting..."
cast send $XAUT \
  "mint(address,uint256)" \
  $DEPLOYER \
  $RAW_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Successfully minted $AMOUNT XAUT!"
echo ""

# Check balance
echo "Checking balance..."
BALANCE_RAW=$(cast call $XAUT "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
BALANCE=$(cast --to-dec $BALANCE_RAW)
BALANCE_HUMAN=$(echo "scale=2; $BALANCE / 1000000" | bc)

echo "Current balance: $BALANCE_HUMAN XAUT"
echo ""
echo "========================================="
echo "✅ Done!"
echo "========================================="
