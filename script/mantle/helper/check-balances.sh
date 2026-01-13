#!/bin/bash

# Check token balances on Mantle Sepolia
# Usage: ./check-balances.sh [address]
# Example: ./check-balances.sh 0xYourAddress

set -e

# Load environment
source .env 2>/dev/null || true

# Check required vars
if [ -z "$MANTLE_SEPOLIA_RPC" ]; then
    echo "Error: MANTLE_SEPOLIA_RPC not set in .env"
    exit 1
fi

# Parse arguments
if [ -z "$1" ]; then
    if [ -z "$PRIVATE_KEY" ]; then
        echo "Usage: ./check-balances.sh <address>"
        exit 1
    fi
    ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
else
    ADDRESS=$1
fi

echo "=============================================="
echo "Token Balances on Mantle Sepolia"
echo "=============================================="
echo "Address: $ADDRESS"
echo ""

# MNT Balance
MNT_BALANCE=$(cast balance $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
echo "MNT: $(cast from-wei $MNT_BALANCE) MNT"

# IDRX Balance
if [ -n "$MOCK_IDRX" ]; then
    IDRX_BALANCE=$(cast call $MOCK_IDRX "balanceOf(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
    IDRX_HUMAN=$(echo "scale=2; $IDRX_BALANCE / 1000000" | bc)
    echo "IDRX: $IDRX_HUMAN IDRX"
fi

# USDC Balance
if [ -n "$MOCK_USDC" ]; then
    USDC_BALANCE=$(cast call $MOCK_USDC "balanceOf(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
    USDC_HUMAN=$(echo "scale=2; $USDC_BALANCE / 1000000" | bc)
    echo "USDC: $USDC_HUMAN USDC"
fi

# XAUT Balance
if [ -n "$XAUT" ]; then
    XAUT_BALANCE=$(cast call $XAUT "balanceOf(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
    XAUT_HUMAN=$(echo "scale=6; $XAUT_BALANCE / 1000000" | bc)
    echo "XAUT: $XAUT_HUMAN XAUT"
fi

echo ""

# KYC Status
if [ -n "$IDENTITY_REGISTRY" ]; then
    IS_VERIFIED=$(cast call $IDENTITY_REGISTRY "isVerified(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
    if [ "$IS_VERIFIED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
        echo "KYC Status: Verified ✓"
    else
        echo "KYC Status: Not Verified ✗"
    fi
fi

# Protocol Position (if BorrowingProtocolV2 is set)
if [ -n "$BORROWING_PROTOCOL_V2" ]; then
    echo ""
    echo "Borrowing Protocol Position:"
    
    COLLATERAL=$(cast call $BORROWING_PROTOCOL_V2 "collateralBalance(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
    COLLATERAL_HUMAN=$(echo "scale=6; $COLLATERAL / 1000000" | bc)
    echo "  Collateral: $COLLATERAL_HUMAN XAUT"
    
    DEBT=$(cast call $BORROWING_PROTOCOL_V2 "debtBalance(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
    DEBT_HUMAN=$(echo "scale=2; $DEBT / 1000000" | bc)
    echo "  Debt: $DEBT_HUMAN IDRX"
    
    if [ "$COLLATERAL" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        LTV=$(cast call $BORROWING_PROTOCOL_V2 "getLTV(address)" $ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
        LTV_PERCENT=$(echo "scale=2; $LTV / 100" | bc)
        echo "  LTV: $LTV_PERCENT%"
    fi
fi

echo ""
echo "=============================================="
