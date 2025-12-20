#!/bin/bash

echo "========================================"
echo " AuRoom Protocol - Deploy Vault Router"
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

echo "[1/3] Deploying GoldVault and SwapRouter..."
echo

forge script script/DeployVaultRouter.s.sol:DeployVaultRouter \
    --rpc-url $MANTLE_TESTNET_RPC \
    --broadcast \
    -vvv

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Deployment failed!"
    exit 1
fi

echo
echo "========================================"
echo " Deployment Successful!"
echo "========================================"
echo
echo "Please update the addresses in:"
echo "- script/SetupVaultRouter.s.sol"
echo "- deployments/auroom-mantle-sepolia.json"
echo
echo "Then run: ./setup-vault-router.sh"
echo
