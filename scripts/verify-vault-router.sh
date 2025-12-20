#!/bin/bash

echo "========================================"
echo " AuRoom Protocol - Verify Vault Router"
echo "========================================"
echo

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "ERROR: .env file not found"
    exit 1
fi

echo "Make sure you have updated the addresses in:"
echo "- script/VerifyVaultRouter.s.sol"
echo

echo "Running verification..."
echo

forge script script/VerifyVaultRouter.s.sol:VerifyVaultRouter \
    --rpc-url $MANTLE_TESTNET_RPC \
    -vvvv

echo
