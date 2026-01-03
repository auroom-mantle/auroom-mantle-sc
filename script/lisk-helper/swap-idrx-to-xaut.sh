#!/bin/bash

# Swap IDRX to XAUT Helper Script
# Usage: ./swap-idrx-to-xaut.sh [amount]
# Example: ./swap-idrx-to-xaut.sh 66000000

# Load environment variables
source .env

# Default values
AMOUNT=${1:-66000000}  # Default: 66M IDRX (≈ 1 XAUT)

# Calculate amount with decimals (IDRX has 6 decimals)
AMOUNT_WITH_DECIMALS=$((AMOUNT * 1000000))

# Calculate minimum output (95% to allow 5% slippage)
# 1 XAUT = 66M IDRX, so AMOUNT / 66M = XAUT amount
XAUT_EXPECTED=$((AMOUNT / 66))  # Approximate XAUT amount
MIN_OUT=$((XAUT_EXPECTED * 950000))  # 95% with 6 decimals

# Deadline: 20 minutes from now
DEADLINE=$(($(date +%s) + 1200))

echo "======================================"
echo "🔄  Swapping IDRX → XAUT"
echo "======================================"
echo "SwapRouter: $SWAP_ROUTER"
echo "Amount In: $AMOUNT IDRX"
echo "Min Out: ~$XAUT_EXPECTED XAUT"
echo "Deadline: $DEADLINE"
echo "======================================"
echo ""

# Execute swap
cast send $SWAP_ROUTER \
  "swapIDRXToXAUT(uint256,uint256,uint256)" \
  $AMOUNT_WITH_DECIMALS \
  $MIN_OUT \
  $DEADLINE \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

echo ""
echo "✅ Swap complete!"
echo ""

# Check new XAUT balance
echo "Checking XAUT balance..."
BALANCE=$(cast call $XAUT "balanceOf(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
BALANCE_DEC=$((16#${BALANCE:2}))
BALANCE_FORMATTED=$((BALANCE_DEC / 1000000))

echo "New XAUT balance: $BALANCE_FORMATTED XAUT"
