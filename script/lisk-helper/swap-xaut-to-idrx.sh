#!/bin/bash

# Execute Swap XAUT to IDRX
# Usage: ./swap-xaut-to-idrx.sh [amount]

# Load environment variables
source .env

# Default values
AMOUNT=${1:-1}  # Default: 1 XAUT

# Calculate amount with decimals (XAUT has 6 decimals)
AMOUNT_WITH_DECIMALS=$((AMOUNT * 1000000))

# Get quote first
echo "======================================"
echo "🔄  Swapping XAUT → IDRX"
echo "======================================"
echo "SwapRouter: $SWAP_ROUTER"
echo "Amount In: $AMOUNT XAUT"
echo "======================================"
echo ""

echo "📈 Getting quote..."
QUOTE=$(cast call $SWAP_ROUTER "getQuoteXAUTtoIDRX(uint256)" $AMOUNT_WITH_DECIMALS --rpc-url $LISK_TESTNET_RPC)
QUOTE_DEC=$((16#${QUOTE:2}))
QUOTE_FORMATTED=$((QUOTE_DEC / 1000000))

echo "Expected output: $QUOTE_FORMATTED IDRX"
echo ""

# Calculate minimum output (95% to allow 5% slippage)
MIN_OUT=$((QUOTE_DEC * 95 / 100))
MIN_OUT_FORMATTED=$((MIN_OUT / 1000000))

echo "Min output (5% slippage): $MIN_OUT_FORMATTED IDRX"
echo ""

# Deadline: 20 minutes from now
DEADLINE=$(($(date +%s) + 1200))

echo "⏳ Executing swap..."
echo ""

# Execute swap
cast send $SWAP_ROUTER \
  "swapXAUTtoIDRX(uint256,uint256,address,uint256)" \
  $AMOUNT_WITH_DECIMALS \
  $MIN_OUT \
  $DEPLOYER \
  $DEADLINE \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

echo ""
echo "✅ Swap complete!"
echo ""

# Check new balances
echo "Checking new balances..."
XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
XAUT_DEC=$((16#${XAUT_BALANCE:2}))
XAUT_FORMATTED=$((XAUT_DEC / 1000000))

IDRX_BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
IDRX_DEC=$((16#${IDRX_BALANCE:2}))
IDRX_FORMATTED=$((IDRX_DEC / 1000000))

echo "New XAUT balance: $XAUT_FORMATTED XAUT"
echo "New IDRX balance: $IDRX_FORMATTED IDRX"
