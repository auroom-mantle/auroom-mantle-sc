#!/bin/bash

# Approve tokens for spending on Mantle Sepolia
# Usage: ./approve-tokens.sh [spender] [token]
# Examples:
#   ./approve-tokens.sh                           # Approve all for SwapRouter
#   ./approve-tokens.sh $SWAP_ROUTER IDRX         # Approve IDRX for SwapRouter
#   ./approve-tokens.sh $BORROWING_PROTOCOL_V2    # Approve all for BorrowingProtocol

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

# Parse arguments
SPENDER=${1:-$SWAP_ROUTER}
TOKEN=${2:-"ALL"}

if [ -z "$SPENDER" ]; then
    echo "Error: No spender specified and SWAP_ROUTER not set"
    exit 1
fi

echo "=============================================="
echo "Approve Tokens on Mantle Sepolia"
echo "=============================================="
echo "Spender: $SPENDER"
echo "Token: $TOKEN"
echo ""

MAX_UINT="0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

approve_token() {
    local TOKEN_ADDRESS=$1
    local TOKEN_NAME=$2
    
    if [ -z "$TOKEN_ADDRESS" ]; then
        echo "Skipping $TOKEN_NAME (not set in .env)"
        return
    fi
    
    echo "Approving $TOKEN_NAME..."
    cast send $TOKEN_ADDRESS \
        "approve(address,uint256)" \
        $SPENDER \
        $MAX_UINT \
        --rpc-url $MANTLE_SEPOLIA_RPC \
        --private-key $PRIVATE_KEY \
        --quiet
    echo "$TOKEN_NAME approved ✓"
}

case $TOKEN in
    "IDRX")
        approve_token $MOCK_IDRX "IDRX"
        ;;
    "USDC")
        approve_token $MOCK_USDC "USDC"
        ;;
    "XAUT")
        approve_token $XAUT "XAUT"
        ;;
    "ALL")
        approve_token $MOCK_IDRX "IDRX"
        approve_token $MOCK_USDC "USDC"
        approve_token $XAUT "XAUT"
        ;;
    *)
        echo "Unknown token: $TOKEN"
        echo "Valid options: IDRX, USDC, XAUT, ALL"
        exit 1
        ;;
esac

echo ""
echo "Done!"
