#!/bin/bash

# Simulate Swap XAUT to IDRX
# Usage: ./simulate-swap-xaut-to-idrx.sh [amount_xaut]

# Load environment variables
source .env

# Amount of XAUT to swap (default: 1 XAUT)
AMOUNT_XAUT=${1:-1}
AMOUNT_XAUT_WEI=$((AMOUNT_XAUT * 1000000))  # 6 decimals

echo "======================================"
echo "🔄  Simulating XAUT → IDRX Swap"
echo "======================================"
echo "Amount In: $AMOUNT_XAUT XAUT"
echo "SwapRouter: $SWAP_ROUTER"
echo "======================================"
echo ""

# Step 1: Check current balances
echo "📊 Current Balances:"
XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
XAUT_DEC=$((16#${XAUT_BALANCE:2}))
XAUT_FORMATTED=$((XAUT_DEC / 1000000))
echo "   XAUT: $XAUT_FORMATTED XAUT"

IDRX_BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
IDRX_DEC=$((16#${IDRX_BALANCE:2}))
IDRX_FORMATTED=$((IDRX_DEC / 1000000))
echo "   IDRX: $IDRX_FORMATTED IDRX"
echo ""

# Step 2: Check liquidity pools
echo "💧 Liquidity Pool Reserves:"
echo ""
echo "   XAUT/USDC Pair:"
RESERVES_XAUT=$(cast call $PAIR_XAUT_USDC "getReserves()" --rpc-url $LISK_TESTNET_RPC)
echo "   Raw: $RESERVES_XAUT"

# Parse reserves (first 32 bytes = reserve0, next 32 bytes = reserve1)
RESERVE0_HEX=${RESERVES_XAUT:2:64}
RESERVE1_HEX=${RESERVES_XAUT:66:64}

RESERVE0=$((16#$RESERVE0_HEX))
RESERVE1=$((16#$RESERVE1_HEX))

echo "   Reserve0: $((RESERVE0 / 1000000)) (token0)"
echo "   Reserve1: $((RESERVE1 / 1000000)) (token1)"
echo ""

echo "   IDRX/USDC Pair:"
RESERVES_IDRX=$(cast call $PAIR_IDRX_USDC "getReserves()" --rpc-url $LISK_TESTNET_RPC)
RESERVE0_HEX_I=${RESERVES_IDRX:2:64}
RESERVE1_HEX_I=${RESERVES_IDRX:66:64}

RESERVE0_I=$((16#$RESERVE0_HEX_I))
RESERVE1_I=$((16#$RESERVE1_HEX_I))

echo "   Reserve0: $((RESERVE0_I / 1000000)) (token0)"
echo "   Reserve1: $((RESERVE1_I / 1000000)) (token1)"
echo ""

# Step 3: Get quote
echo "📈 Getting Quote..."
QUOTE=$(cast call $SWAP_ROUTER "getQuoteXAUTtoIDRX(uint256)" $AMOUNT_XAUT_WEI --rpc-url $LISK_TESTNET_RPC)
QUOTE_DEC=$((16#${QUOTE:2}))
QUOTE_FORMATTED=$((QUOTE_DEC / 1000000))

echo "   Expected Output: $QUOTE_FORMATTED IDRX"
echo ""

# Step 4: Check KYC status
echo "🪪 Checking KYC Status..."
IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $DEPLOYER --rpc-url $LISK_TESTNET_RPC)
if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "   ✅ Deployer is KYC verified"
else
    echo "   ❌ Deployer is NOT KYC verified - SWAP WILL FAIL!"
fi
echo ""

# Step 5: Check approvals
echo "✅ Checking Approvals..."
ALLOWANCE=$(cast call $XAUT "allowance(address,address)" $DEPLOYER $SWAP_ROUTER --rpc-url $LISK_TESTNET_RPC)
ALLOWANCE_DEC=$((16#${ALLOWANCE:2}))
ALLOWANCE_FORMATTED=$((ALLOWANCE_DEC / 1000000))

echo "   XAUT Allowance for SwapRouter: $ALLOWANCE_FORMATTED XAUT"

if [ $ALLOWANCE_DEC -lt $AMOUNT_XAUT_WEI ]; then
    echo "   ⚠️  Insufficient allowance - need to approve first!"
    echo ""
    echo "   Run: ./script/lisk-helper/approve-tokens.sh $SWAP_ROUTER XAUT"
else
    echo "   ✅ Sufficient allowance"
fi
echo ""

# Step 6: Calculate minimum output (95% for 5% slippage)
MIN_OUT=$((QUOTE_DEC * 95 / 100))
MIN_OUT_FORMATTED=$((MIN_OUT / 1000000))

echo "📝 Swap Parameters:"
echo "   Amount In: $AMOUNT_XAUT XAUT ($AMOUNT_XAUT_WEI wei)"
echo "   Min Out: $MIN_OUT_FORMATTED IDRX ($MIN_OUT wei)"
echo "   Slippage: 5%"
echo ""

# Step 7: Summary
echo "======================================"
echo "📋 Summary"
echo "======================================"
echo "Swap: $AMOUNT_XAUT XAUT → ~$QUOTE_FORMATTED IDRX"
echo ""

if [ "$IS_VERIFIED" != "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "❌ WILL FAIL: Not KYC verified"
    echo "   Fix: ./script/lisk-helper/register-kyc.sh"
elif [ $ALLOWANCE_DEC -lt $AMOUNT_XAUT_WEI ]; then
    echo "❌ WILL FAIL: Insufficient allowance"
    echo "   Fix: ./script/lisk-helper/approve-tokens.sh $SWAP_ROUTER XAUT"
elif [ $XAUT_DEC -lt $AMOUNT_XAUT_WEI ]; then
    echo "❌ WILL FAIL: Insufficient XAUT balance"
    echo "   Fix: ./script/lisk-helper/mint-xaut.sh $AMOUNT_XAUT"
else
    echo "✅ Ready to swap!"
    echo ""
    echo "To execute swap, run:"
    echo "cast send $SWAP_ROUTER \\"
    echo "  \"swapXAUTtoIDRX(uint256,uint256,address,uint256)\" \\"
    echo "  $AMOUNT_XAUT_WEI \\"
    echo "  $MIN_OUT \\"
    echo "  $DEPLOYER \\"
    echo "  $(($(date +%s) + 1200)) \\"
    echo "  --rpc-url \$LISK_TESTNET_RPC \\"
    echo "  --private-key \$PRIVATE_KEY"
fi

echo "======================================"
