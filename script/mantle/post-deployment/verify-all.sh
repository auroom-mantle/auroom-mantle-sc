#!/bin/bash

# Verify all deployed contracts on Mantle Sepolia
# Usage: ./verify-all.sh
# Run this script after all contracts are deployed (wait ~1-2 minutes)
#
# Based on Mantle documentation:
# https://docs-v2.mantle.xyz/devs/dev-guides/how-to/verify/foundry

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_API_KEY" ]; then
    echo "Error: MANTLE_API_KEY not set in .env"
    echo "Get your API key from: https://explorer.sepolia.mantle.xyz"
    exit 1
fi

CHAIN_ID=5003
VERIFIER_URL="https://api.etherscan.io/v2/api?chainid=5003"
COMPILER_VERSION="v0.8.30+commit.73712a01"
OPTIMIZER_RUNS=200

echo ""
echo "=============================================="
echo "Verify All Deployed Contracts"
echo "Network: Mantle Sepolia (Chain ID: $CHAIN_ID)"
echo "=============================================="
echo ""
echo "Using Mantle Explorer API for verification"
echo "Compiler: $COMPILER_VERSION"
echo "Optimizer runs: $OPTIMIZER_RUNS"
echo ""

# Delay between verifications (seconds)
DELAY=5

verify_contract() {
    local ADDRESS=$1
    local CONTRACT_NAME=$2
    local CONSTRUCTOR_ARGS=$3
    
    if [ -z "$ADDRESS" ]; then
        echo "⚠️  Skipping $CONTRACT_NAME - address not set"
        return
    fi
    
    echo "📋 Verifying $CONTRACT_NAME at $ADDRESS..."
    
    if [ -n "$CONSTRUCTOR_ARGS" ]; then
        forge verify-contract $ADDRESS $CONTRACT_NAME \
            --verifier-url "$VERIFIER_URL" \
            --etherscan-api-key $MANTLE_API_KEY \
            --compiler-version $COMPILER_VERSION \
            --num-of-optimizations $OPTIMIZER_RUNS \
            --constructor-args $CONSTRUCTOR_ARGS \
            --watch \
            2>&1 || echo "   ⚠️  Verification failed or already verified"
    else
        forge verify-contract $ADDRESS $CONTRACT_NAME \
            --verifier-url "$VERIFIER_URL" \
            --etherscan-api-key $MANTLE_API_KEY \
            --compiler-version $COMPILER_VERSION \
            --num-of-optimizations $OPTIMIZER_RUNS \
            --watch \
            2>&1 || echo "   ⚠️  Verification failed or already verified"
    fi
    
    echo ""
    sleep $DELAY
}

echo "🔍 Starting verification process..."
echo ""

# 1. MockIDRX
verify_contract "$MOCK_IDRX" "src/MockIDRX.sol:MockIDRX"

# 2. MockUSDC
verify_contract "$MOCK_USDC" "src/MockUSDC.sol:MockUSDC"

# 3. IdentityRegistry
verify_contract "$IDENTITY_REGISTRY" "src/IdentityRegistry.sol:IdentityRegistry"

# 4. XAUT (has constructor arg: identityRegistry)
if [ -n "$XAUT" ] && [ -n "$IDENTITY_REGISTRY" ]; then
    XAUT_ARGS=$(cast abi-encode "constructor(address)" $IDENTITY_REGISTRY)
    verify_contract "$XAUT" "src/XAUT.sol:XAUT" "$XAUT_ARGS"
fi

# 5. UniswapV2Factory (no constructor args)
verify_contract "$UNISWAP_FACTORY" "test/mocks/MockUniswapV2Factory.sol:MockUniswapV2Factory"

# 6. UniswapV2Router (constructor arg: factory only)
if [ -n "$UNISWAP_ROUTER" ] && [ -n "$UNISWAP_FACTORY" ]; then
    ROUTER_ARGS=$(cast abi-encode "constructor(address)" $UNISWAP_FACTORY)
    verify_contract "$UNISWAP_ROUTER" "test/mocks/MockUniswapV2Router02.sol:MockUniswapV2Router02" "$ROUTER_ARGS"
fi

# 7. SwapRouter (constructor args: router, idrx, usdc, xaut)
if [ -n "$SWAP_ROUTER" ]; then
    SWAP_ARGS=$(cast abi-encode "constructor(address,address,address,address)" $UNISWAP_ROUTER $MOCK_IDRX $MOCK_USDC $XAUT)
    verify_contract "$SWAP_ROUTER" "src/SwapRouter.sol:SwapRouter" "$SWAP_ARGS"
fi

# 8. BorrowingProtocolV2 (constructor args: xaut, idrx, registry, treasury, price)
if [ -n "$BORROWING_PROTOCOL_V2" ]; then
    TREASURY_ADDR=${TREASURY:-$DEPLOYER}
    INITIAL_PRICE="6600000000000000"
    BP_ARGS=$(cast abi-encode "constructor(address,address,address,address,uint256)" $XAUT $MOCK_IDRX $IDENTITY_REGISTRY $TREASURY_ADDR $INITIAL_PRICE)
    verify_contract "$BORROWING_PROTOCOL_V2" "src/BorrowingProtocolV2.sol:BorrowingProtocolV2" "$BP_ARGS"
fi

echo ""
echo "=============================================="
echo "Verification Complete!"
echo "=============================================="
echo ""
echo "Check your contracts on:"
echo "  Mantle Explorer: https://explorer.sepolia.mantle.xyz"
echo ""
