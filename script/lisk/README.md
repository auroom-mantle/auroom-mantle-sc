# Lisk Sepolia Deployment Scripts

Individual deployment scripts for AuRoom Protocol contracts on Lisk Sepolia Testnet.

## Prerequisites

1. **Fund your wallet** with ETH on Lisk Sepolia:
   - Faucet: https://thirdweb.com/lisk-sepolia-testnet
   - Or: https://sepolia-faucet.lisk.com

2. **Set environment variables** in `.env`:
   ```bash
   PRIVATE_KEY=your_private_key_here
   LISK_TESTNET_RPC=https://rpc.sepolia-api.lisk.com
   ```

## Deployment Order

Deploy contracts in this exact order:

### 1. MockIDRX (Indonesian Rupiah Stablecoin)
```bash
forge script script/lisk/Deploy1_MockIDRX.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --verify
```

After deployment, add to `.env`:
```bash
MOCK_IDRX=<deployed_address>
```

---

### 2. MockUSDC (USD Coin)
```bash
forge script script/lisk/Deploy2_MockUSDC.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --verify
```

After deployment, add to `.env`:
```bash
MOCK_USDC=<deployed_address>
```

---

### 3. IdentityRegistry (KYC System)
```bash
forge script script/lisk/Deploy3_IdentityRegistry.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --verify
```

After deployment, add to `.env`:
```bash
IDENTITY_REGISTRY=<deployed_address>
```

**Note**: This script automatically registers the deployer in KYC.

---

### 4. XAUT (Tokenized Gold)
**Requires**: `IDENTITY_REGISTRY` in `.env`

```bash
forge script script/lisk/Deploy4_XAUT.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --verify
```

After deployment, add to `.env`:
```bash
XAUT=<deployed_address>
```

---

### 5. SwapRouter (IDRX ↔ XAUT Router)
**Requires**: `UNISWAP_ROUTER`, `MOCK_IDRX`, `MOCK_USDC`, `XAUT`, `IDENTITY_REGISTRY` in `.env`

```bash
forge script script/lisk/Deploy5_SwapRouter.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --verify
```

After deployment, add to `.env`:
```bash
SWAP_ROUTER=<deployed_address>
```

**Note**: This script automatically registers SwapRouter in KYC.

---

### 6. GoldVault (ERC-4626 Yield Vault)
**Requires**: `XAUT`, `IDENTITY_REGISTRY`, `UNISWAP_ROUTER`, `MOCK_USDC` in `.env`

```bash
forge script script/lisk/Deploy6_GoldVault.s.sol \
  --rpc-url $LISK_TESTNET_RPC \
  --broadcast \
  --verify
```

After deployment, add to `.env`:
```bash
GOLD_VAULT=<deployed_address>
```

**Note**: This script automatically registers GoldVault in KYC.

---

## Verification

All scripts include `--verify` flag for automatic contract verification on Blockscout.

If verification fails, you can manually verify:

```bash
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
  --chain lisk_testnet \
  --watch
```

For contracts with constructor arguments (e.g., XAUT):
```bash
forge verify-contract <XAUT_ADDRESS> XAUT \
  --chain lisk_testnet \
  --constructor-args $(cast abi-encode "constructor(address)" <IDENTITY_REGISTRY_ADDRESS>) \
  --watch
```

## Block Explorer

View deployed contracts on:
- **Blockscout**: https://sepolia-blockscout.lisk.com

## Network Information

- **Network**: Lisk Sepolia Testnet
- **Chain ID**: 4202
- **RPC URL**: https://rpc.sepolia-api.lisk.com
- **Native Token**: ETH

## Troubleshooting

### "IDENTITY_REGISTRY not set in .env"
Make sure you've deployed IdentityRegistry first and added its address to `.env`.

### "Insufficient funds"
Get more ETH from the faucet: https://thirdweb.com/lisk-sepolia-testnet

### "Verification failed"
Try manual verification using the commands above, or wait a few minutes and retry.

## Current Deployment Status

✅ **Phase 1 Completed** (2026-01-02):
- MockIDRX: `0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519`
- MockUSDC: `0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496`
- IdentityRegistry: `0x34A1D3fff3958843C43aD80F30b94c510645C316`
- XAUT: `0x90193C961A926261B756D1E5bb255e67ff9498A1`

⏳ **Phase 2 Pending**:
- Uniswap V2 Factory & Router
- SwapRouter
- GoldVault
