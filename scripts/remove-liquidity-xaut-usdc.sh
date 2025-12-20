#!/bin/bash

# Remove Liquidity Script - XAUT/USDC
# Removes all liquidity from XAUT/USDC pair

set -e

# Load environment variables
source .env

# Contract addresses
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
ROUTER="0xF01D09A6CF3938d59326126174bD1b32FB47d8F5"
FACTORY="0x8950d0D71a23085C514350df2682c3f6F1D7aBFE"
DEPLOYER="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

echo "========================================="
echo "🔄 Remove XAUT/USDC Liquidity"
echo "========================================="
echo ""

# Get pair address
PAIR=$(cast call $FACTORY "getPair(address,address)(address)" $XAUT $USDC --rpc-url $MANTLE_TESTNET_RPC)
echo "Pair: $PAIR"

# Get LP token balance
LP_BALANCE_RAW=$(cast call $PAIR "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
LP_BALANCE=$(cast --to-dec $LP_BALANCE_RAW 2>/dev/null || echo $LP_BALANCE_RAW)

echo "LP Token Balance: $LP_BALANCE"

if [ "$LP_BALANCE" = "0" ]; then
    echo "❌ No liquidity to remove!"
    exit 1
fi

# Deadline
DEADLINE=$(($(date +%s) + 300))

echo ""
echo "Removing all liquidity..."
echo ""

# Approve LP tokens to router
cast send $PAIR \
  "approve(address,uint256)" \
  $ROUTER \
  $LP_BALANCE \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo "✅ LP tokens approved"
echo ""

# Remove liquidity
cast send $ROUTER \
  "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)" \
  $XAUT \
  $USDC \
  $LP_BALANCE \
  0 \
  0 \
  $DEPLOYER \
  $DEADLINE \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Liquidity removed successfully!"
echo "========================================="
