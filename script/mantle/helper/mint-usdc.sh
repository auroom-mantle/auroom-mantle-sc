#!/bin/bash

# Mint USDC tokens on Mantle Sepolia
# Usage: ./mint-usdc.sh [amount] [recipient]
# Example: ./mint-usdc.sh 100000 0xYourAddress

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

if [ -z "$MOCK_USDC" ]; then
    echo "Error: MOCK_USDC not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

# Parse arguments
AMOUNT=${1:-100000}  # Default: 100K USDC
RECIPIENT=${2:-$(cast wallet address --private-key $PRIVATE_KEY)}

# Convert to wei (6 decimals)
AMOUNT_WEI=$(echo "$AMOUNT * 1000000" | bc)

echo "=============================================="
echo "Minting USDC on Mantle Sepolia"
echo "=============================================="
echo "USDC Contract: $MOCK_USDC"
echo "Recipient: $RECIPIENT"
echo "Amount: $AMOUNT USDC ($AMOUNT_WEI wei)"
echo ""

# Get balance before
BALANCE_BEFORE=$(cast call $MOCK_USDC "balanceOf(address)" $RECIPIENT --rpc-url $MANTLE_SEPOLIA_RPC)
echo "Balance before: $(echo "scale=2; $BALANCE_BEFORE / 1000000" | bc) USDC"

# Mint
echo "Minting..."
cast send $MOCK_USDC \
    "publicMint(address,uint256)" \
    $RECIPIENT \
    $AMOUNT_WEI \
    --rpc-url $MANTLE_SEPOLIA_RPC \
    --private-key $PRIVATE_KEY

# Get balance after
BALANCE_AFTER=$(cast call $MOCK_USDC "balanceOf(address)" $RECIPIENT --rpc-url $MANTLE_SEPOLIA_RPC)
echo "Balance after: $(echo "scale=2; $BALANCE_AFTER / 1000000" | bc) USDC"
echo ""
echo "Done!"
