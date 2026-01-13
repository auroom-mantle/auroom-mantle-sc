#!/bin/bash

# Mint XAUT tokens on Mantle Sepolia
# Usage: ./mint-xaut.sh [amount] [recipient]
# Example: ./mint-xaut.sh 100 0xYourAddress
# Note: Recipient must be registered in IdentityRegistry

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

if [ -z "$XAUT" ]; then
    echo "Error: XAUT not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

# Parse arguments
AMOUNT=${1:-100}  # Default: 100 XAUT
RECIPIENT=${2:-$(cast wallet address --private-key $PRIVATE_KEY)}

# Convert to wei (6 decimals)
AMOUNT_WEI=$(echo "$AMOUNT * 1000000" | bc)

echo "=============================================="
echo "Minting XAUT on Mantle Sepolia"
echo "=============================================="
echo "XAUT Contract: $XAUT"
echo "Recipient: $RECIPIENT"
echo "Amount: $AMOUNT XAUT ($AMOUNT_WEI wei)"
echo ""

# Check if recipient is verified
if [ -n "$IDENTITY_REGISTRY" ]; then
    IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $RECIPIENT --rpc-url $MANTLE_SEPOLIA_RPC)
    if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo "Warning: Recipient is NOT verified in KYC!"
        echo "XAUT mint will fail. Register recipient first."
        exit 1
    fi
    echo "Recipient KYC verified: true"
fi

# Get balance before
BALANCE_BEFORE=$(cast call $XAUT "balanceOf(address)" $RECIPIENT --rpc-url $MANTLE_SEPOLIA_RPC)
echo "Balance before: $(echo "scale=6; $BALANCE_BEFORE / 1000000" | bc) XAUT"

# Mint (owner only function)
echo "Minting..."
cast send $XAUT \
    "mint(address,uint256)" \
    $RECIPIENT \
    $AMOUNT_WEI \
    --rpc-url $MANTLE_SEPOLIA_RPC \
    --private-key $PRIVATE_KEY

# Get balance after
BALANCE_AFTER=$(cast call $XAUT "balanceOf(address)" $RECIPIENT --rpc-url $MANTLE_SEPOLIA_RPC)
echo "Balance after: $(echo "scale=6; $BALANCE_AFTER / 1000000" | bc) XAUT"
echo ""
echo "Done!"
