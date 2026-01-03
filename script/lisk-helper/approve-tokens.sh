#!/bin/bash

# Approve Tokens Helper Script
# Usage: ./approve-tokens.sh [spender] [token]
# Example: ./approve-tokens.sh 0x8cDE80170b877a51a17323628BA6221F6F023505 IDRX

# Load environment variables
source .env

# Parameters
SPENDER=${1:-$SWAP_ROUTER}  # Default: SwapRouter
TOKEN_NAME=${2:-"ALL"}  # Default: approve all tokens

# Max uint256 for unlimited approval
MAX_UINT256="115792089237316195423570985008687907853269984665640564039457584007913129639935"

echo "======================================"
echo "✅  Approving Tokens"
echo "======================================"
echo "Spender: $SPENDER"
echo "======================================"
echo ""

approve_token() {
    local TOKEN_ADDRESS=$1
    local TOKEN_SYMBOL=$2
    
    echo "Approving $TOKEN_SYMBOL..."
    cast send $TOKEN_ADDRESS \
      "approve(address,uint256)" \
      $SPENDER \
      $MAX_UINT256 \
      --rpc-url $LISK_TESTNET_RPC \
      --private-key $PRIVATE_KEY
    
    echo "✅ $TOKEN_SYMBOL approved!"
    echo ""
}

# Approve based on token selection
if [ "$TOKEN_NAME" == "ALL" ] || [ "$TOKEN_NAME" == "IDRX" ]; then
    approve_token $MOCK_IDRX "IDRX"
fi

if [ "$TOKEN_NAME" == "ALL" ] || [ "$TOKEN_NAME" == "USDC" ]; then
    approve_token $MOCK_USDC "USDC"
fi

if [ "$TOKEN_NAME" == "ALL" ] || [ "$TOKEN_NAME" == "XAUT" ]; then
    approve_token $XAUT "XAUT"
fi

echo "======================================"
echo "✅ All approvals complete!"
echo "======================================"
