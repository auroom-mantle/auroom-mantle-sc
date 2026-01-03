#!/bin/bash

# Register KYC Helper Script
# Usage: ./register-kyc.sh [address]
# Example: ./register-kyc.sh 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1

# Load environment variables
source .env

# Address to register
USER_ADDRESS=${1:-$DEPLOYER}

echo "======================================"
echo "🪪  Registering KYC"
echo "======================================"
echo "Identity Registry: $IDENTITY_REGISTRY"
echo "User Address: $USER_ADDRESS"
echo "======================================"
echo ""

# Check if already registered
echo "Checking current KYC status..."
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $USER_ADDRESS --rpc-url $LISK_TESTNET_RPC)

if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "✅ Address is already KYC verified!"
    exit 0
fi

echo "⏳ Registering identity..."

# Register identity
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address)" \
  $USER_ADDRESS \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

echo ""
echo "✅ KYC registration complete!"
echo ""

# Verify registration
echo "Verifying registration..."
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $USER_ADDRESS --rpc-url $LISK_TESTNET_RPC)

if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "✅ Confirmed: Address is now KYC verified!"
else
    echo "❌ Error: Registration failed"
fi
