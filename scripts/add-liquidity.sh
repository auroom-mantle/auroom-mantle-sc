#!/bin/bash

# Script untuk menambahkan liquidity menggunakan cast
# Pastikan .env sudah di-load atau export PRIVATE_KEY dan RPC_URL

set -e

# Load environment variables
source .env

# Contract addresses
IDRX="0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05"
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"
ROUTER="0xF01D09A6CF3938d59326126174bD1b32FB47d8F5"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

# Amounts
IDRX_AMOUNT="100000000"              # 1M IDRX (2 decimals)
USDC_FOR_IDRX="65000000000"          # 65K USDC (6 decimals)
XAUT_AMOUNT="100000000"              # 100 XAUT (6 decimals)
USDC_FOR_XAUT="270000000000"         # 270K USDC (6 decimals)
TOTAL_USDC="335000000000"            # 335K USDC total

# Slippage tolerance (95%)
IDRX_MIN="95000000"                  # 95% of IDRX
USDC_IDRX_MIN="61750000000"          # 95% of USDC for IDRX
XAUT_MIN="95000000"                  # 95% of XAUT
USDC_XAUT_MIN="256500000000"         # 95% of USDC for XAUT

# Deadline (5 minutes from now)
DEADLINE=$(($(date +%s) + 300))

echo "========================================="
echo "Adding Liquidity to DEX Pairs"
echo "========================================="
echo "Router: $ROUTER"
echo "Deployer: $DEPLOYER"
echo ""

# Check balances first
echo "Checking balances..."
echo ""

# Check ETH balance for gas
ETH_BALANCE=$(cast balance $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC)
echo "ETH Balance: $ETH_BALANCE wei"
ETH_IN_ETHER=$(cast --to-unit $ETH_BALANCE ether)
echo "ETH Balance: $ETH_IN_ETHER ETH"

# Minimum ETH required (approximately 0.01 ETH for gas)
MIN_ETH="10000000000000000"  # 0.01 ETH in wei
if [ $(echo "$ETH_BALANCE < $MIN_ETH" | bc) -eq 1 ]; then
    echo "❌ ERROR: Insufficient ETH balance for gas fees!"
    echo "   Required: ~0.01 ETH"
    echo "   Current: $ETH_IN_ETHER ETH"
    exit 1
fi
echo "✅ ETH balance sufficient for gas"
echo ""

# Check IDRX balance
IDRX_BALANCE_RAW=$(cast call $IDRX "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
IDRX_BALANCE=$(cast --to-dec $IDRX_BALANCE_RAW)
echo "IDRX Balance: $IDRX_BALANCE (raw)"
echo "IDRX Balance: $(echo "scale=2; $IDRX_BALANCE / 100" | bc) IDRX"

if [ $IDRX_BALANCE -lt $IDRX_AMOUNT ]; then
    echo "❌ ERROR: Insufficient IDRX balance!"
    echo "   Required: $IDRX_AMOUNT ($(echo "scale=2; $IDRX_AMOUNT / 100" | bc) IDRX)"
    echo "   Current: $IDRX_BALANCE ($(echo "scale=2; $IDRX_BALANCE / 100" | bc) IDRX)"
    exit 1
fi
echo "✅ IDRX balance sufficient"
echo ""

# Check USDC balance
USDC_BALANCE_RAW=$(cast call $USDC "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
USDC_BALANCE=$(cast --to-dec $USDC_BALANCE_RAW)
echo "USDC Balance: $USDC_BALANCE (raw)"
echo "USDC Balance: $(echo "scale=2; $USDC_BALANCE / 1000000" | bc) USDC"

if [ $USDC_BALANCE -lt $TOTAL_USDC ]; then
    echo "❌ ERROR: Insufficient USDC balance!"
    echo "   Required: $TOTAL_USDC ($(echo "scale=2; $TOTAL_USDC / 1000000" | bc) USDC)"
    echo "   Current: $USDC_BALANCE ($(echo "scale=2; $USDC_BALANCE / 1000000" | bc) USDC)"
    exit 1
fi
echo "✅ USDC balance sufficient"
echo ""

# Check XAUT balance
XAUT_BALANCE_RAW=$(cast call $XAUT "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
XAUT_BALANCE=$(cast --to-dec $XAUT_BALANCE_RAW)
echo "XAUT Balance: $XAUT_BALANCE (raw)"
echo "XAUT Balance: $(echo "scale=2; $XAUT_BALANCE / 1000000" | bc) XAUT"

if [ $XAUT_BALANCE -lt $XAUT_AMOUNT ]; then
    echo "❌ ERROR: Insufficient XAUT balance!"
    echo "   Required: $XAUT_AMOUNT ($(echo "scale=2; $XAUT_AMOUNT / 1000000" | bc) XAUT)"
    echo "   Current: $XAUT_BALANCE ($(echo "scale=2; $XAUT_BALANCE / 1000000" | bc) XAUT)"
    exit 1
fi
echo "✅ XAUT balance sufficient"
echo ""

echo "========================================="
echo "All balances verified! Proceeding..."
echo "========================================="
echo ""

# Step 1: Approve IDRX
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

# Step 2: Approve USDC (total amount)
echo "Step 2: Approving USDC..."
cast send $USDC \
  "approve(address,uint256)" \
  $ROUTER \
  $TOTAL_USDC \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ USDC approved"
echo ""

# Step 3: Approve XAUT
echo "Step 3: Approving XAUT..."
cast send $XAUT \
  "approve(address,uint256)" \
  $ROUTER \
  $XAUT_AMOUNT \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ XAUT approved"
echo ""

# Step 4: Add IDRX/USDC liquidity
echo "Step 4: Adding IDRX/USDC liquidity..."
echo "  IDRX: $IDRX_AMOUNT (1M IDRX)"
echo "  USDC: $USDC_FOR_IDRX (65K USDC)"
echo "  Deadline: $DEADLINE"

cast send $ROUTER \
  "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)" \
  $IDRX \
  $USDC \
  $IDRX_AMOUNT \
  $USDC_FOR_IDRX \
  $IDRX_MIN \
  $USDC_IDRX_MIN \
  $DEPLOYER \
  $DEADLINE \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ IDRX/USDC liquidity added"
echo ""

# Step 5: Add XAUT/USDC liquidity
echo "Step 5: Adding XAUT/USDC liquidity..."
echo "  XAUT: $XAUT_AMOUNT (100 XAUT)"
echo "  USDC: $USDC_FOR_XAUT (270K USDC)"
echo "  Deadline: $DEADLINE"

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

echo "✅ XAUT/USDC liquidity added"
echo ""
echo "========================================="
echo "✅ All liquidity added successfully!"
echo "========================================="
