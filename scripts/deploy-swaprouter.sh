#!/bin/bash

echo "========================================"
echo " Deploy SwapRouter"
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

echo "Deploying SwapRouter to Mantle Sepolia..."
echo

forge script script/DeploySwapRouter.s.sol:DeploySwapRouter \
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
echo " SwapRouter Deployed Successfully!"
echo "========================================"
echo
echo "Copy the address above and update:"
echo "- script/SetupVaultRouter.s.sol (SWAP_ROUTER)"
echo "- script/VerifyVaultRouter.s.sol (SWAP_ROUTER)"
echo "- deployments/auroom-mantle-sepolia.json"
echo
