#!/bin/bash

# Interactive Token Minting Script
# Mint IDRX, USDC, or XAUT tokens to any address

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

# Default recipient (deployer)
DEFAULT_RECIPIENT="0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1"

echo "========================================="
echo "🪙  Interactive Token Minting Tool"
echo "========================================="
echo ""

# Select token
echo "Select token to mint:"
echo "1) IDRX (6 decimals)"
echo "2) USDC (6 decimals)"
echo "3) XAUT (6 decimals)"
echo ""
read -p "Enter choice [1-3]: " token_choice

case $token_choice in
    1)
        TOKEN_ADDRESS=$IDRX
        TOKEN_NAME="IDRX"
        TOKEN_DECIMALS=6
        ;;
    2)
        TOKEN_ADDRESS=$USDC
        TOKEN_NAME="USDC"
        TOKEN_DECIMALS=6
        ;;
    3)
        TOKEN_ADDRESS=$XAUT
        TOKEN_NAME="XAUT"
        TOKEN_DECIMALS=6
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "Selected: $TOKEN_NAME"
echo "Address: $TOKEN_ADDRESS"
echo ""

# Enter recipient address
read -p "Enter recipient address (press Enter for deployer: $DEFAULT_RECIPIENT): " recipient
if [ -z "$recipient" ]; then
    recipient=$DEFAULT_RECIPIENT
fi

echo ""
echo "Recipient: $recipient"
echo ""

# Enter amount
echo "Enter amount to mint (in human-readable format):"
echo "Examples:"
echo "  - For 1,000,000 $TOKEN_NAME, enter: 1000000"
echo "  - For 335,000 $TOKEN_NAME, enter: 335000"
echo "  - For 100 $TOKEN_NAME, enter: 100"
echo ""
read -p "Amount: " human_amount

if [ -z "$human_amount" ]; then
    echo "❌ Amount cannot be empty!"
    exit 1
fi

# Convert to wei (multiply by 10^decimals)
if [ $TOKEN_DECIMALS -eq 6 ]; then
    raw_amount=$(echo "$human_amount * 1000000" | bc | cut -d'.' -f1)
elif [ $TOKEN_DECIMALS -eq 2 ]; then
    raw_amount=$(echo "$human_amount * 100" | bc | cut -d'.' -f1)
else
    raw_amount=$(echo "$human_amount * 10^$TOKEN_DECIMALS" | bc | cut -d'.' -f1)
fi

echo ""
echo "========================================="
echo "📋 Minting Summary"
echo "========================================="
echo "Token: $TOKEN_NAME"
echo "Recipient: $recipient"
echo "Amount: $human_amount $TOKEN_NAME"
echo "Raw Amount: $raw_amount"
echo ""
read -p "Proceed with minting? [y/N]: " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Minting cancelled."
    exit 0
fi

echo ""
echo "🚀 Minting $human_amount $TOKEN_NAME to $recipient..."
echo ""

# Call publicMint function
cast send $TOKEN_ADDRESS \
  "publicMint(address,uint256)" \
  $recipient \
  $raw_amount \
  --rpc-url $MANTLE_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Successfully minted $human_amount $TOKEN_NAME!"
echo ""

# Check new balance
echo "Checking new balance..."
BALANCE_RAW=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $recipient --rpc-url $MANTLE_TESTNET_RPC | awk '{print $1}')
BALANCE=$(cast --to-dec $BALANCE_RAW)
BALANCE_HUMAN=$(echo "scale=2; $BALANCE / 10^$TOKEN_DECIMALS" | bc)

echo "New balance: $BALANCE_HUMAN $TOKEN_NAME"
echo ""
echo "========================================="
echo "✅ Minting Complete!"
echo "========================================="
