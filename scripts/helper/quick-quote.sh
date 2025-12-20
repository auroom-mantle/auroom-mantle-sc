#!/bin/bash

# Quick Quote Script
# Usage: ./quick-quote.sh [from_token] [to_token] [amount]
# Example: ./quick-quote.sh idrx usdc 1000

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
ROUTER="0xF01D09A6CF3938d59326126174bD1b32FB47d8F5"

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
        echo "Usage: $0 [idrx|usdc|xaut] [idrx|usdc|xaut] [amount]"
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
        echo "Usage: $0 [idrx|usdc|xaut] [idrx|usdc|xaut] [amount]"
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
echo "🔍 Quick Quote"
echo "========================================="
echo "Swap: $AMOUNT $FROM_NAME → $TO_NAME"
echo ""

# Build path array
PATH_ARRAY="[$FROM_TOKEN,$TO_TOKEN]"

echo "Getting quote from router..."
echo "Path: $FROM_NAME → $TO_NAME"
echo ""

# Get quote with full output for debugging
RESULT=$(cast call $ROUTER \
  "getAmountsOut(uint256,address[])(uint256[])" \
  $RAW_AMOUNT \
  "$PATH_ARRAY" \
  --rpc-url $MANTLE_TESTNET_RPC 2>&1)

# Check if call failed
if [[ $RESULT == *"error"* ]] || [[ $RESULT == *"Error"* ]]; then
    echo "❌ ERROR: Failed to get quote"
    echo "   $RESULT"
    exit 1
fi

echo "Raw result: $RESULT"
echo ""

# Parse result - remove brackets and get second value
# Result format: [inputAmount, outputAmount]
CLEAN_RESULT=$(echo $RESULT | tr -d '[]' | tr ',' ' ')
INPUT_RETURNED=$(echo $CLEAN_RESULT | awk '{print $1}')
OUTPUT_RAW=$(echo $CLEAN_RESULT | awk '{print $2}')

echo "Parsed output (raw): $OUTPUT_RAW"

# Convert to decimal
if [[ -z "$OUTPUT_RAW" ]] || [[ "$OUTPUT_RAW" == "0" ]]; then
    echo ""
    echo "❌ ERROR: No liquidity or invalid path!"
    echo "   This pair may not have liquidity yet."
    echo "   Available pairs:"
    echo "   - IDRX ↔ USDC"
    echo "   - XAUT ↔ USDC"
    exit 1
fi

OUTPUT_AMOUNT=$OUTPUT_RAW

# Calculate human-readable output
OUTPUT_HUMAN=$(echo "scale=6; $OUTPUT_AMOUNT / 1000000" | bc)

# Calculate price
PRICE=$(echo "scale=6; $OUTPUT_HUMAN / $AMOUNT" | bc)

echo "========================================="
echo "✅ Quote Result"
echo "========================================="
echo "Input:  $AMOUNT $FROM_NAME"
echo "Output: $OUTPUT_HUMAN $TO_NAME"
echo ""
echo "Rate: 1 $FROM_NAME = $PRICE $TO_NAME"
echo "========================================="
