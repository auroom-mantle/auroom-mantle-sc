#!/bin/bash

# Add XAUT/USDC Liquidity Only
# This script adds liquidity to XAUT/USDC pair

set -e

# Load environment variables
source .env

# Contract addresses
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
ROUTER="0xF01D09A6CF3938d59326126174bD1b32FB47d8F5"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Amounts for XAUT/USDC
XAUT_AMOUNT="100000000"              # 100 XAUT (6 decimals)
USDC_FOR_XAUT="270000000000"         # 270K USDC (6 decimals)

# Slippage tolerance (95%)
XAUT_MIN="95000000"                  # 95% of XAUT
USDC_XAUT_MIN="256500000000"         # 95% of USDC for XAUT

# Deadline (5 minutes from now)
DEADLINE=$(($(date +%s) + 300))

echo "========================================="
echo "Adding XAUT/USDC Liquidity"
echo "========================================="
echo "Router: $ROUTER"
echo "Deployer: $DEPLOYER"
echo ""

# Check balances
echo "Checking balances..."
echo ""

# Check USDC balance
USDC_BALANCE_RAW=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
USDC_BALANCE=$(cast --to-dec $USDC_BALANCE_RAW)
echo "USDC Balance: $(echo "scale=2; $USDC_BALANCE / 1000000" | bc) USDC"

if [ $USDC_BALANCE -lt $USDC_FOR_XAUT ]; then
    echo "❌ ERROR: Insufficient USDC balance!"
    echo "   Required: 270,000 USDC"
    echo "   Current: $(echo "scale=2; $USDC_BALANCE / 1000000" | bc) USDC"
    exit 1
fi

# Check XAUT balance
XAUT_BALANCE_RAW=$(cast call $XAUT "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
XAUT_BALANCE=$(cast --to-dec $XAUT_BALANCE_RAW)
echo "XAUT Balance: $(echo "scale=2; $XAUT_BALANCE / 1000000" | bc) XAUT"

if [ $XAUT_BALANCE -lt $XAUT_AMOUNT ]; then
    echo "❌ ERROR: Insufficient XAUT balance!"
    echo "   Required: 100 XAUT"
    echo "   Current: $(echo "scale=2; $XAUT_BALANCE / 1000000" | bc) XAUT"
    exit 1
fi

echo "✅ All balances sufficient"
echo ""

# Approve USDC
echo "Step 1: Approving USDC..."
cast send $USDC \
  "approve(address,uint256)" \
  $ROUTER \
  $USDC_FOR_XAUT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ USDC approved"
echo ""

# Approve XAUT
echo "Step 2: Approving XAUT..."
cast send $XAUT \
  "approve(address,uint256)" \
  $ROUTER \
  $XAUT_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ XAUT approved"
echo ""

# Add XAUT/USDC liquidity
echo "Step 3: Adding XAUT/USDC liquidity..."
echo "  XAUT: $XAUT_AMOUNT (100 XAUT)"
echo "  USDC: $USDC_FOR_XAUT (270K USDC)"
echo "  Deadline: $DEADLINE"
echo ""

cast send $ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $XAUT \
  $USDC \
  $XAUT_AMOUNT \
  $USDC_FOR_XAUT \
  $XAUT_MIN \
  $USDC_XAUT_MIN \
  $DEPLOYER \
  $DEADLINE \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ XAUT/USDC liquidity added"
echo ""
echo "========================================="
echo "✅ All liquidity added successfully!"
echo "========================================="
