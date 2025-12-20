#!/bin/bash

# Add Liquidity with Correct Ratio
# 1 USDC = 16,500 IDRX (real-world rate)

set -e

# Load environment variables
source .env

# Contract addresses
IDRX="0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05"
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
ROUTER="0xF01D09A6CF3938d59326126174bD1b32FB47d8F5"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Correct amounts for 1 USDC = 16,500 IDRX
# Using 10,000 USDC as base
USDC_AMOUNT="10000000000"           # 10,000 USDC (6 decimals)
IDRX_AMOUNT="165000000000000"       # 165,000,000 IDRX (6 decimals) = 10,000 * 16,500

# Slippage tolerance (95%)
USDC_MIN="9500000000"               # 95% of USDC
IDRX_MIN="156750000000000"          # 95% of IDRX

# Deadline
DEADLINE=$(($(date +%s) + 300))

echo "========================================="
echo "➕ Add IDRX/USDC Liquidity (Correct Ratio)"
echo "========================================="
echo "Target Rate: 1 USDC = 16,500 IDRX"
echo ""
echo "Amounts:"
echo "  IDRX: 165,000,000 IDRX"
echo "  USDC: 10,000 USDC"
echo ""

# Check balances
echo "Checking balances..."
IDRX_BALANCE_RAW=$(cast call $IDRX "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
IDRX_BALANCE=$(cast --to-dec $IDRX_BALANCE_RAW 2>/dev/null || echo $IDRX_BALANCE_RAW)

USDC_BALANCE_RAW=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
USDC_BALANCE=$(cast --to-dec $USDC_BALANCE_RAW 2>/dev/null || echo $USDC_BALANCE_RAW)

echo "IDRX Balance: $(echo "scale=2; $IDRX_BALANCE / 1000000" | bc) IDRX"
echo "USDC Balance: $(echo "scale=2; $USDC_BALANCE / 1000000" | bc) USDC"
echo ""

if [ $IDRX_BALANCE -lt $IDRX_AMOUNT ]; then
    NEEDED=$(echo "scale=0; ($IDRX_AMOUNT - $IDRX_BALANCE) / 1000000" | bc)
    echo "❌ Insufficient IDRX! Need to mint $NEEDED more IDRX"
    echo "   Run: ./scripts/helper/quick-mint-idrx.sh $NEEDED"
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
echo "Step 1: Approving IDRX..."
cast send $IDRX \
  "approve(address,uint256)" \
  $ROUTER \
  $IDRX_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ IDRX approved"
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
  $IDRX \
  $USDC \
  $IDRX_AMOUNT \
  $USDC_AMOUNT \
  $IDRX_MIN \
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
echo "New Rate: 1 USDC = 16,500 IDRX"
echo "========================================="
