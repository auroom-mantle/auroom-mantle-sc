#!/bin/bash

# Direct Quote Script - Query pair reserves directly
# This bypasses the router's getAmountsOut which has init code hash issues
# Usage: ./direct-quote.sh [from_token] [to_token] [amount]

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
USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
XAUT="0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78"
FACTORY="0x8950d0D71a23085C514350df2682c3f6F1D7aBFE"

# Parse arguments
FROM_TOKEN_TYPE=${1:-idrx}
TO_TOKEN_TYPE=${2:-usdc}
AMOUNT=${3:-1000}

# Get FROM token
case $FROM_TOKEN_TYPE in
    idrx|IDRX)
        FROM_TOKEN=$IDRX
        FROM_NAME="IDRX"
        ;;
    usdc|USDC)
        FROM_TOKEN=$USDC
        FROM_NAME="USDC"
        ;;
    xaut|XAUT)
        FROM_TOKEN=$XAUT
        FROM_NAME="XAUT"
        ;;
    *)
        echo "❌ Invalid FROM token!"
        exit 1
        ;;
esac

# Get TO token
case $TO_TOKEN_TYPE in
    idrx|IDRX)
        TO_TOKEN=$IDRX
        TO_NAME="IDRX"
        ;;
    usdc|USDC)
        TO_TOKEN=$USDC
        TO_NAME="USDC"
        ;;
    xaut|XAUT)
        TO_TOKEN=$XAUT
        TO_NAME="XAUT"
        ;;
    *)
        echo "❌ Invalid TO token!"
        exit 1
        ;;
esac

# Check if same token
if [ "$FROM_TOKEN" = "$TO_TOKEN" ]; then
    echo "❌ ERROR: FROM and TO tokens must be different!"
    exit 1
fi

# Convert to raw amount (6 decimals)
RAW_AMOUNT=$(echo "$AMOUNT * 1000000" | bc | cut -d'.' -f1)

echo "========================================="
echo "🔍 Direct Quote (via Pair Reserves)"
echo "========================================="
echo "Swap: $AMOUNT $FROM_NAME → $TO_NAME"
echo ""

# Get pair address from factory
PAIR=$(cast call $FACTORY "getPair(address,address)(address)" $FROM_TOKEN $TO_TOKEN --rpc-url $MANTLE_TESTNET_RPC)

if [ "$PAIR" = "0x0000000000000000000000000000000000000000" ]; then
    echo "❌ ERROR: No pair exists for $FROM_NAME/$TO_NAME"
    exit 1
fi

echo "Pair address: $PAIR"

# Get reserves - extract first value from each line (before scientific notation)
RESERVES_RAW=$(cast call $PAIR "getReserves()(uint112,uint112,uint32)" --rpc-url $MANTLE_TESTNET_RPC)
RESERVE0=$(echo "$RESERVES_RAW" | head -1 | awk '{print $1}')
RESERVE1=$(echo "$RESERVES_RAW" | head -2 | tail -1 | awk '{print $1}')

echo "Reserves: $RESERVE0, $RESERVE1"

# Get token0 and token1 to determine which reserve is which
TOKEN0=$(cast call $PAIR "token0()(address)" --rpc-url $MANTLE_TESTNET_RPC)
TOKEN1=$(cast call $PAIR "token1()(address)" --rpc-url $MANTLE_TESTNET_RPC)

echo "Token0: $TOKEN0"
echo "Token1: $TOKEN1"
echo ""

# Determine reserve order
if [ "$FROM_TOKEN" = "$TOKEN0" ]; then
    RESERVE_IN=$RESERVE0
    RESERVE_OUT=$RESERVE1
else
    RESERVE_IN=$RESERVE1
    RESERVE_OUT=$RESERVE0
fi

# Convert reserves to decimal (remove scientific notation)
RESERVE_IN_DEC=$(cast --to-dec $RESERVE_IN 2>/dev/null || echo $RESERVE_IN)
RESERVE_OUT_DEC=$(cast --to-dec $RESERVE_OUT 2>/dev/null || echo $RESERVE_OUT)

echo "Reserve IN:  $RESERVE_IN_DEC"
echo "Reserve OUT: $RESERVE_OUT_DEC"
echo ""

# Calculate output using Uniswap formula: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
# Using bc for precision
AMOUNT_IN_WITH_FEE=$(echo "$RAW_AMOUNT * 997" | bc)
NUMERATOR=$(echo "$AMOUNT_IN_WITH_FEE * $RESERVE_OUT_DEC" | bc)
DENOMINATOR=$(echo "$RESERVE_IN_DEC * 1000 + $AMOUNT_IN_WITH_FEE" | bc)
OUTPUT_AMOUNT=$(echo "$NUMERATOR / $DENOMINATOR" | bc)

# Calculate human-readable output
OUTPUT_HUMAN=$(echo "scale=6; $OUTPUT_AMOUNT / 1000000" | bc)

# Calculate price
PRICE=$(echo "scale=6; $OUTPUT_HUMAN / $AMOUNT" | bc)

# Calculate price impact
SPOT_PRICE=$(echo "scale=6; $RESERVE_OUT_DEC / $RESERVE_IN_DEC" | bc)
EFFECTIVE_PRICE=$(echo "scale=6; $OUTPUT_AMOUNT / $RAW_AMOUNT" | bc)
PRICE_IMPACT=$(echo "scale=2; (1 - $EFFECTIVE_PRICE / $SPOT_PRICE) * 100" | bc)

echo "========================================="
echo "✅ Quote Result"
echo "========================================="
echo "Input:  $AMOUNT $FROM_NAME"
echo "Output: $OUTPUT_HUMAN $TO_NAME"
echo ""
echo "Rate: 1 $FROM_NAME = $PRICE $TO_NAME"
echo "Price Impact: $PRICE_IMPACT%"
echo "========================================="
