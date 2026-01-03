#!/bin/bash

# Mint XAUT Helper Script
# Usage: ./mint-xaut.sh [amount] [recipient]
# Example: ./mint-xaut.sh 1000 0x742812a2Ff08b76f968dffA7ca6892A428cAeBb1

# Load environment variables
source .env

# Default values
AMOUNT=${1:-1000}  # Default: 1,000 XAUT
RECIPIENT=${2:-$DEPLOYER}  # Default: deployer address

# Calculate amount with decimals (XAUT has 6 decimals)
AMOUNT_WITH_DECIMALS=$((AMOUNT * 1000000))

echo "======================================"
echo "🏆  Minting XAUT (Gold)"
echo "======================================"
echo "Contract: $XAUT"
echo "Recipient: $RECIPIENT"
echo "Amount: $AMOUNT XAUT"
echo "Amount (raw): $AMOUNT_WITH_DECIMALS"
echo "======================================"
echo ""

# Execute mint
cast send $XAUT \
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
BALANCE=$(cast call $XAUT "balanceOf(address)" $RECIPIENT --rpc-url $LISK_TESTNET_RPC)
BALANCE_DEC=$((16#${BALANCE:2}))
BALANCE_FORMATTED=$((BALANCE_DEC / 1000000))

echo "New balance: $BALANCE_FORMATTED XAUT"
