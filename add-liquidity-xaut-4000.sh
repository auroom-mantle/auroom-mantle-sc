#!/bin/bash

# Add XAUT/USDC Liquidity with Correct Ratio
# 1 XAUT = 4,000 USDC

set -e

# Load environment variables
source .env

# Contract addresses
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
ROUTER="0xF01D09A6CF3938d59326126174bD1b32FB47d8F5"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Correct amounts for 1 XAUT = 4,000 USDC
# Using 100 XAUT as base
XAUT_AMOUNT="100000000"             # 100 XAUT (6 decimals)
USDC_AMOUNT="400000000000"          # 400,000 USDC (6 decimals) = 100 * 4,000

# Slippage tolerance (95%)
XAUT_MIN="95000000"                 # 95% of XAUT
USDC_MIN="380000000000"             # 95% of USDC

# Deadline
DEADLINE=$(($(date +%s) + 300))

echo "========================================="
echo "➕ Add XAUT/USDC Liquidity (Correct Ratio)"
echo "========================================="
echo "Target Rate: 1 XAUT = 4,000 USDC"
echo ""
echo "Amounts:"
echo "  XAUT: 100 XAUT"
echo "  USDC: 400,000 USDC"
echo ""

# Check balances
echo "Checking balances..."
XAUT_BALANCE_RAW=$(cast call $XAUT "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
XAUT_BALANCE=$(cast --to-dec $XAUT_BALANCE_RAW 2>/dev/null || echo $XAUT_BALANCE_RAW)

USDC_BALANCE_RAW=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
USDC_BALANCE=$(cast --to-dec $USDC_BALANCE_RAW 2>/dev/null || echo $USDC_BALANCE_RAW)

echo "XAUT Balance: $(echo "scale=2; $XAUT_BALANCE / 1000000" | bc) XAUT"
echo "USDC Balance: $(echo "scale=2; $USDC_BALANCE / 1000000" | bc) USDC"
echo ""

if [ $XAUT_BALANCE -lt $XAUT_AMOUNT ]; then
    NEEDED=$(echo "scale=0; ($XAUT_AMOUNT - $XAUT_BALANCE) / 1000000" | bc)
    echo "❌ Insufficient XAUT! Need to mint $NEEDED more XAUT"
    echo "   Run: ./scripts/helper/quick-mint-xaut.sh $NEEDED"
    exit 1
fi

if [ $USDC_BALANCE -lt $USDC_AMOUNT ]; then
    NEEDED=$(echo "scale=0; ($USDC_AMOUNT - $USDC_BALANCE) / 1000000" | bc)
    echo "❌ Insufficient USDC! Need to mint $NEEDED more USDC"
    echo "   Run: ./scripts/helper/quick-mint-usdc.sh $NEEDED"
    exit 1
fi

echo "✅ Balances sufficient"
echo ""

# Approve tokens
echo "Step 1: Approving XAUT..."
cast send $XAUT \
  "approve(address,uint256)" \
  $ROUTER \
  $XAUT_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ XAUT approved"
echo ""

echo "Step 2: Approving USDC..."
cast send $USDC \
  "approve(address,uint256)" \
  $ROUTER \
  $USDC_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ USDC approved"
echo ""

# Add liquidity
echo "Step 3: Adding liquidity..."
cast send $ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $XAUT \
  $USDC \
  $XAUT_AMOUNT \
  $USDC_AMOUNT \
  $XAUT_MIN \
  $USDC_MIN \
  $DEPLOYER \
  $DEADLINE \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Liquidity added successfully!"
echo ""
echo "========================================="
echo "New Rate: 1 XAUT = 4,000 USDC"
echo "========================================="
