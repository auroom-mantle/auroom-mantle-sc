#!/bin/bash

# Check liquidity pool reserves on Mantle Sepolia
# Usage: ./check-liquidity.sh

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

echo "=============================================="
echo "Liquidity Pool Reserves on Mantle Sepolia"
echo "=============================================="
echo ""

# Check IDRX/USDC Pair
if [ -n "$PAIR_IDRX_USDC" ]; then
    echo "IDRX/USDC Pair: $PAIR_IDRX_USDC"
    
    RESERVES=$(cast call $PAIR_IDRX_USDC "getReserves()" --rpc-url $MANTLE_SEPOLIA_RPC)
    
    # Parse reserves (bytes32 format)
    RESERVE0=$(echo $RESERVES | cut -c3-66)
    RESERVE1=$(echo $RESERVES | cut -c67-130)
    
    RESERVE0_DEC=$((16#$RESERVE0))
    RESERVE1_DEC=$((16#$RESERVE1))
    
    echo "  Reserve0: $(echo "scale=2; $RESERVE0_DEC / 1000000" | bc)"
    echo "  Reserve1: $(echo "scale=2; $RESERVE1_DEC / 1000000" | bc)"
    echo "  Expected ratio: 1 USDC = 16,500 IDRX"
    echo ""
fi

# Check XAUT/USDC Pair
if [ -n "$PAIR_XAUT_USDC" ]; then
    echo "XAUT/USDC Pair: $PAIR_XAUT_USDC"
    
    RESERVES=$(cast call $PAIR_XAUT_USDC "getReserves()" --rpc-url $MANTLE_SEPOLIA_RPC)
    
    # Parse reserves
    RESERVE0=$(echo $RESERVES | cut -c3-66)
    RESERVE1=$(echo $RESERVES | cut -c67-130)
    
    RESERVE0_DEC=$((16#$RESERVE0))
    RESERVE1_DEC=$((16#$RESERVE1))
    
    echo "  Reserve0: $(echo "scale=6; $RESERVE0_DEC / 1000000" | bc)"
    echo "  Reserve1: $(echo "scale=2; $RESERVE1_DEC / 1000000" | bc)"
    echo "  Expected ratio: 1 XAUT = 4,000 USDC"
    echo ""
fi

echo "=============================================="
