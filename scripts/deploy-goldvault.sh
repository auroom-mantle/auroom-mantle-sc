#!/bin/bash

echo "========================================"
echo " Deploy GoldVault"
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

echo "Deploying GoldVault to Mantle Sepolia..."
echo

forge script script/DeployGoldVault.s.sol:DeployGoldVault \
    --rpc-url $MANTLE_TESTNET_RPC \
    --broadcast \
    -vvvv

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Deployment failed!"
    exit 1
fi

echo
echo "========================================"
echo " GoldVault Deployed Successfully!"
echo "========================================"
echo
echo "Copy the address above and update:"
echo "- script/SetupVaultRouter.s.sol (GOLD_VAULT)"
echo "- script/VerifyVaultRouter.s.sol (GOLD_VAULT)"
echo "- deployments/auroom-mantle-sepolia.json"
echo
