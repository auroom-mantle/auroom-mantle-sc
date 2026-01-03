#!/bin/bash

# Check Liquidity Pools Helper Script
# Usage: ./check-liquidity.sh

# Load environment variables
source .env

echo "======================================"
echo "💧  Liquidity Pool Status"
echo "======================================"
echo ""

# IDRX/USDC Pair
echo "🔹 IDRX/USDC Pair"
echo "   Address: $PAIR_IDRX_USDC"
echo ""

RESERVES=$(cast call $PAIR_IDRX_USDC "getReserves()" --rpc-url $LISK_TESTNET_RPC)
# Parse reserves (returns 3 values: reserve0, reserve1, blockTimestampLast)
RESERVE0=$(echo $RESERVES | cut -d' ' -f1)
RESERVE1=$(echo $RESERVES | cut -d' ' -f2)

RESERVE0_DEC=$((16#${RESERVE0:2}))
RESERVE1_DEC=$((16#${RESERVE1:2}))

RESERVE0_FORMATTED=$((RESERVE0_DEC / 1000000))
RESERVE1_FORMATTED=$((RESERVE1_DEC / 1000000))

echo "   Reserve IDRX: $RESERVE0_FORMATTED IDRX"
echo "   Reserve USDC: $RESERVE1_FORMATTED USDC"
echo ""

# XAUT/USDC Pair
echo "🔹 XAUT/USDC Pair"
echo "   Address: $PAIR_XAUT_USDC"
echo ""

RESERVES=$(cast call $PAIR_XAUT_USDC "getReserves()" --rpc-url $LISK_TESTNET_RPC)
RESERVE0=$(echo $RESERVES | cut -d' ' -f1)
RESERVE1=$(echo $RESERVES | cut -d' ' -f2)

RESERVE0_DEC=$((16#${RESERVE0:2}))
RESERVE1_DEC=$((16#${RESERVE1:2}))

RESERVE0_FORMATTED=$((RESERVE0_DEC / 1000000))
RESERVE1_FORMATTED=$((RESERVE1_DEC / 1000000))

echo "   Reserve XAUT: $RESERVE0_FORMATTED XAUT"
echo "   Reserve USDC: $RESERVE1_FORMATTED USDC"
echo ""

echo "======================================"
