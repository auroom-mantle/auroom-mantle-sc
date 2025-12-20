#!/bin/bash

# Test Quote Script - Simulate swap quotes using getAmountsOut
# This script helps you see how much output you'll get for a given input

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

echo "========================================="
echo "🔍 DEX Quote Simulator"
echo "========================================="
echo ""

# Select input token
echo "Select INPUT token:"
echo "1) IDRX"
echo "2) USDC"
echo "3) XAUT"
echo ""
read -p "Enter choice [1-3]: " input_choice

case $input_choice in
    1)
        INPUT_TOKEN=$IDRX
        INPUT_NAME="IDRX"
        INPUT_DECIMALS=6
        ;;
    2)
        INPUT_TOKEN=$USDC
        INPUT_NAME="USDC"
        INPUT_DECIMALS=6
        ;;
    3)
        INPUT_TOKEN=$XAUT
        INPUT_NAME="XAUT"
        INPUT_DECIMALS=6
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "Selected INPUT: $INPUT_NAME"
echo ""

# Select output token
echo "Select OUTPUT token:"
echo "1) IDRX"
echo "2) USDC"
echo "3) XAUT"
echo ""
read -p "Enter choice [1-3]: " output_choice

case $output_choice in
    1)
        OUTPUT_TOKEN=$IDRX
        OUTPUT_NAME="IDRX"
        OUTPUT_DECIMALS=6
        ;;
    2)
        OUTPUT_TOKEN=$USDC
        OUTPUT_NAME="USDC"
        OUTPUT_DECIMALS=6
        ;;
    3)
        OUTPUT_TOKEN=$XAUT
        OUTPUT_NAME="XAUT"
        OUTPUT_DECIMALS=6
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "Selected OUTPUT: $OUTPUT_NAME"
echo ""

# Check if same token
if [ "$INPUT_TOKEN" = "$OUTPUT_TOKEN" ]; then
    echo "❌ ERROR: Input and output tokens must be different!"
    exit 1
fi

# Enter amount
echo "Enter amount of $INPUT_NAME to swap:"
echo "Examples:"
echo "  - For 1,000 $INPUT_NAME, enter: 1000"
echo "  - For 100 $INPUT_NAME, enter: 100"
echo "  - For 10 $INPUT_NAME, enter: 10"
echo ""
read -p "Amount: " human_amount

if [ -z "$human_amount" ]; then
    echo "❌ Amount cannot be empty!"
    exit 1
fi

# Convert to raw amount
RAW_AMOUNT=$(echo "$human_amount * 1000000" | bc | cut -d'.' -f1)

echo ""
echo "========================================="
echo "📊 Quote Request"
echo "========================================="
echo "Swap: $human_amount $INPUT_NAME → $OUTPUT_NAME"
echo "Router: $ROUTER"
echo ""

# Build path array
PATH_ARRAY="[$INPUT_TOKEN,$OUTPUT_TOKEN]"

echo "Fetching quote..."
echo ""

# Get quote
RESULT=$(cast call $ROUTER \
  "getAmountsOut(uint256,address[])(uint256[])" \
  $RAW_AMOUNT \
  "$PATH_ARRAY" \
  --rpc-url $MANTLE_TESTNET_RPC)

# Parse result - getAmountsOut returns array [inputAmount, outputAmount]
# Extract the second value (output amount)
OUTPUT_RAW=$(echo $RESULT | sed 's/\[//g' | sed 's/\]//g' | awk '{print $2}' | tr -d ',')

# Convert to decimal if it's in hex
if [[ $OUTPUT_RAW == 0x* ]]; then
    OUTPUT_AMOUNT=$(cast --to-dec $OUTPUT_RAW)
else
    # Remove any scientific notation
    OUTPUT_AMOUNT=$(echo $OUTPUT_RAW | awk '{print $1}')
    OUTPUT_AMOUNT=$(cast --to-dec $OUTPUT_AMOUNT 2>/dev/null || echo $OUTPUT_RAW)
fi

# Calculate human-readable output
OUTPUT_HUMAN=$(echo "scale=6; $OUTPUT_AMOUNT / 1000000" | bc)

# Calculate price
PRICE=$(echo "scale=6; $OUTPUT_HUMAN / $human_amount" | bc)

echo "========================================="
echo "✅ Quote Result"
echo "========================================="
echo "Input:  $human_amount $INPUT_NAME"
echo "Output: $OUTPUT_HUMAN $OUTPUT_NAME"
echo ""
echo "Price: 1 $INPUT_NAME = $PRICE $OUTPUT_NAME"
echo ""
echo "Raw amounts:"
echo "  Input:  $RAW_AMOUNT"
echo "  Output: $OUTPUT_AMOUNT"
echo "========================================="
