#!/bin/bash

# Script to get the correct INIT_CODE_HASH for your factory

set -e

source .env

FACTORY="0x8950d0D71a23085C514350df2682c3f6F1D7aBFE"

echo "========================================="
echo "🔍 Getting INIT_CODE_HASH"
echo "========================================="
echo ""

# Method 1: Try to call INIT_CODE_PAIR_HASH() if it exists
echo "Method 1: Checking if factory has INIT_CODE_PAIR_HASH()..."
INIT_HASH=$(cast call $FACTORY "INIT_CODE_PAIR_HASH()(bytes32)" --rpc-url $MANTLE_TESTNET_RPC 2>/dev/null || echo "")

if [ -n "$INIT_HASH" ] && [ "$INIT_HASH" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    echo "✅ Found INIT_CODE_PAIR_HASH: $INIT_HASH"
else
    echo "❌ Factory doesn't expose INIT_CODE_PAIR_HASH"
    echo ""
    echo "Method 2: Calculate from existing pair..."
    
    # Get an existing pair
    IDRX="0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05"
    USDC="0x96ABff3a2668B811371d7d763f06B3832CEdf38d"
    
    PAIR=$(cast call $FACTORY "getPair(address,address)(address)" $IDRX $USDC --rpc-url $MANTLE_TESTNET_RPC)
    echo "Existing pair: $PAIR"
    
    # Get pair bytecode
    echo ""
    echo "Getting pair bytecode..."
    BYTECODE=$(cast code $PAIR --rpc-url $MANTLE_TESTNET_RPC)
    
    # This won't give us the init code directly, but we can calculate it
    # from the deployed bytecode pattern
    
    echo ""
    echo "⚠️  To get the exact init code hash, you need to:"
    echo "1. Check the factory deployment transaction"
    echo "2. Or redeploy with a factory that exposes INIT_CODE_PAIR_HASH"
    echo "3. Or calculate from UniswapV2Pair.sol compilation"
    
    echo ""
    echo "For now, use factory.getPair() instead of pairFor()"
fi

echo ""
echo "========================================="
echo "Current (wrong) hash in library:"
echo "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
echo "========================================="
