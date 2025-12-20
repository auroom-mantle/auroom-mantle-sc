#!/bin/bash

# Quick Mint USDC Script
# Usage: ./quick-mint-usdc.sh [amount]
# Default: 1,000,000 USDC

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Contract addresses
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Parse amount (default: 1,000,000 USDC)
AMOUNT=${1:-1000000}

# Convert to raw amount (6 decimals)
RAW_AMOUNT=$(echo "$AMOUNT * 1000000" | bc | cut -d'.' -f1)

echo "========================================="
echo "🪙  Quick Mint: USDC"
echo "========================================="
echo "Token: USDC ($USDC)"
echo "Recipient: $DEPLOYER"
echo "Amount: $AMOUNT USDC"
echo "Raw Amount: $RAW_AMOUNT"
echo ""

# Mint tokens
echo "🚀 Minting..."
cast send $USDC \
  "publicMint(address,uint256)" \
  $DEPLOYER \
  $RAW_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Successfully minted $AMOUNT USDC!"
echo ""

# Check balance
echo "Checking balance..."
BALANCE_RAW=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
BALANCE=$(cast --to-dec $BALANCE_RAW)
BALANCE_HUMAN=$(echo "scale=2; $BALANCE / 1000000" | bc)

echo "Current balance: $BALANCE_HUMAN USDC"
echo ""
echo "========================================="
echo "✅ Done!"
echo "========================================="
