# 🛠️ Lisk Helper Scripts

Collection of helper scripts for interacting with AuRoom Protocol on Lisk Sepolia.

## 📋 Prerequisites

- Foundry installed (`forge`, `cast`)
- `.env` file configured with proper values
- Bash shell (macOS/Linux)

## 🚀 Quick Start

Make all scripts executable:
```bash
chmod +x script/lisk-helper/*.sh
```

## 📜 Available Scripts

### 1. Minting Tokens

#### Mint IDRX
```bash
./script/lisk-helper/mint-idrx.sh [amount] [recipient]

# Examples:
./script/lisk-helper/mint-idrx.sh 1000000000                    # Mint 1B IDRX to deployer
./script/lisk-helper/mint-idrx.sh 500000000 0xYourAddress       # Mint 500M IDRX to specific address
```

#### Mint USDC
```bash
./script/lisk-helper/mint-usdc.sh [amount] [recipient]

# Examples:
./script/lisk-helper/mint-usdc.sh 100000                        # Mint 100K USDC to deployer
./script/lisk-helper/mint-usdc.sh 50000 0xYourAddress           # Mint 50K USDC to specific address
```

#### Mint XAUT (Gold)
```bash
./script/lisk-helper/mint-xaut.sh [amount] [recipient]

# Examples:
./script/lisk-helper/mint-xaut.sh 1000                          # Mint 1000 XAUT to deployer
./script/lisk-helper/mint-xaut.sh 500 0xYourAddress             # Mint 500 XAUT to specific address
```

---

### 2. Balance Checking

#### Check All Token Balances
```bash
./script/lisk-helper/check-balances.sh [address]

# Examples:
./script/lisk-helper/check-balances.sh                          # Check deployer balances
./script/lisk-helper/check-balances.sh 0xYourAddress            # Check specific address
```

---

### 3. KYC Management

#### Register Address in KYC
```bash
./script/lisk-helper/register-kyc.sh [address]

# Examples:
./script/lisk-helper/register-kyc.sh                            # Register deployer
./script/lisk-helper/register-kyc.sh 0xYourAddress              # Register specific address
```

---

### 4. Token Approvals

#### Approve Tokens for Spending
```bash
./script/lisk-helper/approve-tokens.sh [spender] [token]

# Examples:
./script/lisk-helper/approve-tokens.sh                          # Approve all tokens for SwapRouter
./script/lisk-helper/approve-tokens.sh $SWAP_ROUTER IDRX        # Approve only IDRX
./script/lisk-helper/approve-tokens.sh $BORROWING_PROTOCOL_V2   # Approve all for BorrowingProtocol
```

Supported tokens: `IDRX`, `USDC`, `XAUT`, `ALL`

---

### 5. Swapping

#### Swap IDRX to XAUT
```bash
./script/lisk-helper/swap-idrx-to-xaut.sh [amount]

# Examples:
./script/lisk-helper/swap-idrx-to-xaut.sh 66000000              # Swap 66M IDRX (≈ 1 XAUT)
./script/lisk-helper/swap-idrx-to-xaut.sh 132000000             # Swap 132M IDRX (≈ 2 XAUT)
```

**Note**: Current ratio is 1 XAUT = 66M IDRX (based on 1 XAUT = 4000 USDC, 1 USDC = 16,500 IDRX)

---

### 6. Liquidity Monitoring

#### Check Liquidity Pool Reserves
```bash
./script/lisk-helper/check-liquidity.sh

# Shows reserves for:
# - IDRX/USDC Pair
# - XAUT/USDC Pair
```

---

## 🔧 Common Workflows

### Setup New Test User
```bash
# 1. Register in KYC
./script/lisk-helper/register-kyc.sh 0xNewUserAddress

# 2. Mint tokens
./script/lisk-helper/mint-idrx.sh 1000000000 0xNewUserAddress
./script/lisk-helper/mint-usdc.sh 100000 0xNewUserAddress

# 3. Check balances
./script/lisk-helper/check-balances.sh 0xNewUserAddress
```

### Test Swap Flow
```bash
# 1. Mint IDRX
./script/lisk-helper/mint-idrx.sh 200000000

# 2. Approve SwapRouter
./script/lisk-helper/approve-tokens.sh $SWAP_ROUTER IDRX

# 3. Swap IDRX to XAUT
./script/lisk-helper/swap-idrx-to-xaut.sh 66000000

# 4. Check balances
./script/lisk-helper/check-balances.sh
```

### Monitor Protocol
```bash
# Check liquidity pools
./script/lisk-helper/check-liquidity.sh

# Check deployer balances
./script/lisk-helper/check-balances.sh
```

---

## 📝 Environment Variables Required

Make sure your `.env` file contains:
```bash
PRIVATE_KEY=your_private_key
LISK_TESTNET_RPC=https://rpc.sepolia-api.lisk.com
DEPLOYER=your_deployer_address
MOCK_IDRX=0xCd88C2886A1958BA36238A070e71B51CF930b44d
MOCK_USDC=0xA8F2b8180caFC670f4a24114FDB9c50361038857
XAUT=0xDb198BEaccC55934062Be9AAEdce332c40A1f1Ed
IDENTITY_REGISTRY=0x799fe52FA871EB8e4420fEc9d1b81c6297e712a5
SWAP_ROUTER=0x8cDE80170b877a51a17323628BA6221F6F023505
BORROWING_PROTOCOL_V2=0xA89448b60C4771Fe0C38ba29000AbFdB85E1f6aF
PAIR_IDRX_USDC=0x478FA3880F8474E50ECEDDA71a1D56d5560b1E3f
PAIR_XAUT_USDC=0xBdfD81D4e79c0cC949BB52941BCd30Ed8b3B4112
```

---

## 🔗 Contract Addresses (Lisk Sepolia)

| Contract | Address |
|----------|---------|
| IDRX | `0xCd88C2886A1958BA36238A070e71B51CF930b44d` |
| USDC | `0xA8F2b8180caFC670f4a24114FDB9c50361038857` |
| XAUT | `0xDb198BEaccC55934062Be9AAEdce332c40A1f1Ed` |
| Identity Registry | `0x799fe52FA871EB8e4420fEc9d1b81c6297e712a5` |
| SwapRouter | `0x8cDE80170b877a51a17323628BA6221F6F023505` |
| BorrowingProtocolV2 | `0xA89448b60C4771Fe0C38ba29000AbFdB85E1f6aF` |

---

## ⚠️ Important Notes

- All scripts use `publicMint()` for easy testing (no owner required)
- Default slippage for swaps: 5%
- Deadline for swaps: 20 minutes
- All amounts are in human-readable format (scripts handle decimals)

---

## 🐛 Troubleshooting

### Script not executable
```bash
chmod +x script/lisk-helper/*.sh
```

### Environment variables not loaded
```bash
# Make sure you're in the project root
cd /path/to/auroom-lisk-sc
source .env
```

### Transaction failed
- Check if address is KYC registered (for XAUT operations)
- Check if tokens are approved (for swap/borrow operations)
- Check if you have enough gas (ETH)

---

## 📚 Resources

- [Lisk Sepolia Explorer](https://sepolia-blockscout.lisk.com)
- [Lisk Sepolia Faucet](https://sepolia-faucet.lisk.com)
- [Cast Documentation](https://book.getfoundry.sh/reference/cast/)
