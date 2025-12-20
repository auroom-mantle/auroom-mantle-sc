#!/bin/bash

# Quick Mint IDRX Script
# Usage: ./quick-mint-idrx.sh [amount]
# Default: 1,000,000 IDRX

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Contract addresses
IDRX="0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Parse amount (default: 1,000,000 IDRX)
AMOUNT=${1:-1000000}

# Convert to raw amount (6 decimals)
RAW_AMOUNT=$(echo "$AMOUNT * 1000000" | bc | cut -d'.' -f1)

echo "========================================="
echo "🪙  Quick Mint: IDRX"
echo "========================================="
echo "Token: IDRX ($IDRX)"
echo "Recipient: $DEPLOYER"
echo "Amount: $AMOUNT IDRX"
echo "Raw Amount: $RAW_AMOUNT"
echo ""

# Mint tokens
echo "🚀 Minting..."
cast send $IDRX \
  "publicMint(address,uint256)" \
  $DEPLOYER \
  $RAW_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Successfully minted $AMOUNT IDRX!"
echo ""

# Check balance
echo "Checking balance..."
BALANCE_RAW=$(cast call $IDRX "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
BALANCE=$(cast --to-dec $BALANCE_RAW)
BALANCE_HUMAN=$(echo "scale=2; $BALANCE / 1000000" | bc)

echo "Current balance: $BALANCE_HUMAN IDRX"
echo ""
echo "========================================="
echo "✅ Done!"
echo "========================================="
