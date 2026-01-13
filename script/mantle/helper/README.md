# Mantle Sepolia Helper Scripts

Utility shell scripts for interacting with AuRoom Protocol on Mantle Sepolia.

## Prerequisites

- Foundry installed (`forge`, `cast`)
- `.env` file configured with proper values
- Bash shell (macOS/Linux)

## Quick Start

Make all scripts executable:
```bash
chmod +x script/mantle/helper/*.sh
```

## Available Scripts

### Token Minting

```bash
# Mint IDRX
./script/mantle/helper/mint-idrx.sh [amount] [recipient]
./script/mantle/helper/mint-idrx.sh 1000000000              # Mint 1B IDRX to deployer
./script/mantle/helper/mint-idrx.sh 500000000 0xAddress     # Mint 500M IDRX to address

# Mint USDC
./script/mantle/helper/mint-usdc.sh [amount] [recipient]
./script/mantle/helper/mint-usdc.sh 100000                  # Mint 100K USDC to deployer

# Mint XAUT (requires KYC)
./script/mantle/helper/mint-xaut.sh [amount] [recipient]
./script/mantle/helper/mint-xaut.sh 100                     # Mint 100 XAUT to deployer
```

### Balance Checking

```bash
# Check all balances
./script/mantle/helper/check-balances.sh [address]
./script/mantle/helper/check-balances.sh                    # Check deployer
./script/mantle/helper/check-balances.sh 0xAddress          # Check specific address
```

### KYC Management

```bash
# Register address in KYC
./script/mantle/helper/register-kyc.sh [address]
./script/mantle/helper/register-kyc.sh                      # Register deployer
./script/mantle/helper/register-kyc.sh 0xAddress            # Register specific address
```

### Token Approvals

```bash
# Approve tokens for spending
./script/mantle/helper/approve-tokens.sh [spender] [token]
./script/mantle/helper/approve-tokens.sh                    # Approve all for SwapRouter
./script/mantle/helper/approve-tokens.sh $SWAP_ROUTER IDRX  # Approve only IDRX
./script/mantle/helper/approve-tokens.sh $BORROWING_PROTOCOL_V2  # Approve all for Protocol
```

### Liquidity Monitoring

```bash
# Check liquidity pool reserves
./script/mantle/helper/check-liquidity.sh
```

### Borrowing Simulation

```bash
# Simulate deposit and borrow flow
./script/mantle/helper/simulate-borrow.sh [collateral_xaut] [borrow_idrx]
./script/mantle/helper/simulate-borrow.sh 10 40000000       # 10 XAUT, 40M IDRX
```

## Common Workflows

### Setup New Test User
```bash
# 1. Register in KYC
./script/mantle/helper/register-kyc.sh 0xNewUserAddress

# 2. Mint tokens
./script/mantle/helper/mint-idrx.sh 1000000000 0xNewUserAddress
./script/mantle/helper/mint-xaut.sh 100 0xNewUserAddress

# 3. Check balances
./script/mantle/helper/check-balances.sh 0xNewUserAddress
```

### Test Borrow Flow
```bash
# 1. Mint XAUT to yourself
./script/mantle/helper/mint-xaut.sh 100

# 2. Approve BorrowingProtocol
./script/mantle/helper/approve-tokens.sh $BORROWING_PROTOCOL_V2 XAUT

# 3. Simulate borrow
./script/mantle/helper/simulate-borrow.sh 10 40000000

# 4. Check position
./script/mantle/helper/check-balances.sh
```

## Environment Variables Required

```bash
PRIVATE_KEY=your_private_key
MANTLE_SEPOLIA_RPC=https://rpc.sepolia.mantle.xyz
MOCK_IDRX=0x...
MOCK_USDC=0x...
XAUT=0x...
IDENTITY_REGISTRY=0x...
SWAP_ROUTER=0x...
BORROWING_PROTOCOL_V2=0x...
PAIR_IDRX_USDC=0x...
PAIR_XAUT_USDC=0x...
```

## Troubleshooting

### Script not executable
```bash
chmod +x script/mantle/helper/*.sh
```

### Environment variables not loaded
```bash
cd /path/to/auroom-mantle-sc
source .env
```

### Transaction failed
- Check if address is KYC registered (for XAUT operations)
- Check if tokens are approved (for swap/borrow operations)
- Check if you have enough gas (MNT)

## Network Information

- **Network**: Mantle Sepolia Testnet
- **Chain ID**: 5003
- **RPC URL**: https://rpc.sepolia.mantle.xyz
- **Block Explorer**: https://explorer.sepolia.mantle.xyz
- **Faucet**: https://faucet.sepolia.mantle.xyz
