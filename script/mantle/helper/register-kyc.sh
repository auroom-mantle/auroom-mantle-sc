#!/bin/bash

# Register address in KYC on Mantle Sepolia
# Usage: ./register-kyc.sh [address]
# Example: ./register-kyc.sh 0xYourAddress

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

if [ -z "$IDENTITY_REGISTRY" ]; then
    echo "Error: IDENTITY_REGISTRY not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

# Parse arguments
ADDRESS=${1:-$(cast wallet address --private-key $PRIVATE_KEY)}

echo "=============================================="
echo "Register in KYC on Mantle Sepolia"
echo "=============================================="
echo "IdentityRegistry: $IDENTITY_REGISTRY"
echo "Address to register: $ADDRESS"
echo ""

# Check if already verified
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "Address is already verified!"
    exit 0
fi

echo "Current status: Not Verified"
echo "Registering..."

# Register
cast send $IDENTITY_REGISTRY \
    "registerIdentity(address)" \
    $ADDRESS \
    --rpc-url $MANTLE_SEPOLIA_RPC \
    --private-key $PRIVATE_KEY

# Verify
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo ""
    echo "Registration successful!"
    echo "Address is now verified ✓"
else
    echo ""
    echo "Registration may have failed. Please check manually."
fi
