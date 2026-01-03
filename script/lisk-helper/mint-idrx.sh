#!/bin/bash

# Mint IDRX Helper Script
# Usage: ./mint-idrx.sh [amount] [recipient]
# Example: ./mint-idrx.sh 1000000000 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1

# Load environment variables
source .env

# Default values
AMOUNT=${1:-1000000000}  # Default: 1 billion IDRX
RECIPIENT=${2:-$DEPLOYER}  # Default: deployer address

# Calculate amount with decimals (IDRX has 6 decimals)
AMOUNT_WITH_DECIMALS=$((AMOUNT * 1000000))

echo "======================================"
echo "🪙  Minting IDRX"
echo "======================================"
echo "Contract: $MOCK_IDRX"
echo "Recipient: $RECIPIENT"
echo "Amount: $AMOUNT IDRX"
echo "Amount (raw): $AMOUNT_WITH_DECIMALS"
echo "======================================"
echo ""

# Execute mint
cast send $MOCK_IDRX \
  "publicMint(address,uint256)" \
  $RECIPIENT \
  $AMOUNT_WITH_DECIMALS \
  --rpc-url $LISK_TESTNET_RPC \
  --private-key $PRIVATE_KEY

echo ""
echo "✅ Mint complete!"
echo ""

# Check balance
echo "Checking balance..."
BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $RECIPIENT --rpc-url $LISK_TESTNET_RPC)
BALANCE_DEC=$((16#${BALANCE:2}))
BALANCE_FORMATTED=$((BALANCE_DEC / 1000000))

echo "New balance: $BALANCE_FORMATTED IDRX"
