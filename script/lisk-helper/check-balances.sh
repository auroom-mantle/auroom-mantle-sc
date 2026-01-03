#!/bin/bash

# Check Token Balances Helper Script
# Usage: ./check-balances.sh [address]
# Example: ./check-balances.sh 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1

# Load environment variables
source .env

# Default to deployer address
ADDRESS=${1:-$DEPLOYER}

echo "======================================"
echo "💰  Token Balances"
echo "======================================"
echo "Address: $ADDRESS"
echo "======================================"
echo ""

# Check ETH balance
echo "🔹 ETH Balance:"
ETH_BALANCE=$(cast balance $ADDRESS --rpc-url $LISK_TESTNET_RPC)
ETH_FORMATTED=$(cast --from-wei $ETH_BALANCE)
echo "   $ETH_FORMATTED ETH"
echo ""

# Check IDRX balance
echo "🔹 IDRX Balance:"
IDRX_BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $ADDRESS --rpc-url $LISK_TESTNET_RPC)
IDRX_DEC=$((16#${IDRX_BALANCE:2}))
IDRX_FORMATTED=$((IDRX_DEC / 1000000))
echo "   $IDRX_FORMATTED IDRX"
echo ""

# Check USDC balance
echo "🔹 USDC Balance:"
USDC_BALANCE=$(cast call $MOCK_USDC "balanceOf(address)" $ADDRESS --rpc-url $LISK_TESTNET_RPC)
USDC_DEC=$((16#${USDC_BALANCE:2}))
USDC_FORMATTED=$((USDC_DEC / 1000000))
echo "   $USDC_FORMATTED USDC"
echo ""

# Check XAUT balance
echo "🔹 XAUT Balance:"
XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)" $ADDRESS --rpc-url $LISK_TESTNET_RPC)
XAUT_DEC=$((16#${XAUT_BALANCE:2}))
XAUT_FORMATTED=$((XAUT_DEC / 1000000))
echo "   $XAUT_FORMATTED XAUT"
echo ""

echo "======================================"
