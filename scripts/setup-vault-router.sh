#!/bin/bash

echo "========================================"
echo " AuRoom Protocol - Setup Vault Router"
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
echo "- script/SetupVaultRouter.s.sol"
echo
read -p "Continue? (y/n): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo
echo "[1/1] Registering GoldVault and SwapRouter in IdentityRegistry..."
echo

forge script script/SetupVaultRouter.s.sol:SetupVaultRouter \
    --rpc-url $MANTLE_TESTNET_RPC \
    --broadcast \
    -vvvv

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Setup failed!"
    exit 1
fi

echo
echo "========================================"
echo " Setup Complete!"
echo "========================================"
echo
echo "Your contracts are now ready to use:"
echo "- Users can deposit XAUT into GoldVault"
echo "- Users can swap IDRX <-> XAUT via SwapRouter"
echo
