# 🏆 AuRoom Protocol - Smart Contracts

<div align="center">

![AuRoom Banner](https://img.shields.io/badge/AuRoom-Protocol-gold?style=for-the-badge&logo=ethereum&logoColor=white)

**From Rupiah to Yield-Bearing Gold**

[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-363636?style=flat-square&logo=solidity)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-1.5.0-orange?style=flat-square)](https://getfoundry.sh/)
[![Mantle](https://img.shields.io/badge/Mantle-Sepolia-green?style=flat-square)](https://mantle.xyz/)
[![Tests](https://img.shields.io/badge/Tests-106%2F106%20Passing-brightgreen?style=flat-square)](./test)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](./LICENSE)

[Live Demo](https://auroom-mantle-testnet.vercel.app) • [Frontend Repo](https://github.com/auroom-mantle/auroom-mantle-fe) • [Backend Repo](https://github.com/auroom-mantle/auroom-mantle-be) • [Documentation](#-documentation)

</div>

---

## 📖 Overview

**AuRoom** is a Real World Asset (RWA) protocol that enables Indonesian users to access instant cash loans in IDRX (Indonesian Rupiah stablecoin) using tokenized gold (XAUT) as collateral, with integrated fiat redemption to convert IDRX back to Indonesian Rupiah (IDR).

### The Problem

| Gold Liquidity Trap in Indonesia | The Cost |
|-------------------------------------|-------------|
| Sell gold instantly | 8–12% loss due to bid-ask spreads |
| Use pawnshops | Slow, bureaucratic process |
| Hold and wait | Miss critical emergency cash needs |

### The Solution: AuRoom

| AuRoom Feature | Benefit |
|-------------------|-----------|
| Intent-Based Emergency Flow | Enter IDR needed, gold buffer calculated automatically |
| Partial Liquidity Access | Unlock only what you need, keep the rest |
| Direct Gold-to-Bank Settlement | Cash sent straight to your bank account |
| Emergency-First UX | No crypto jargon, designed for speed |
| On-Chain Security | Transparent smart contracts + bank API integration |

---

## 🏗️ Architecture

```
                    ┌─────────────────┐
                    │   User (KYC'd)  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │   Swap   │   │  Borrow  │   │  Redeem  │
       │IDRX→XAUT │   │XAUT→IDRX │   │IDRX→IDR  │
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            ▼              ▼              ▼
     ┌────────────┐ ┌──────────────┐ ┌─────────┐
     │ SwapRouter │ │ Borrowing    │ │ IDRX    │
     │            │ │ ProtocolV2   │ │ Burn +  │
     └─────┬──────┘ └──────────────┘ │ API     │
           │                         └─────────┘
           ▼
    ┌─────────────┐
    │ Uniswap V2  │
    │   Router    │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌─────────┐
│IDRX/USDC│ │XAUT/USDC│
│  Pair   │ │  Pair   │
└─────────┘ └─────────┘
```

### How Cash Loan Works

```
User deposits XAUT collateral
        │
        ▼
   ┌──────────────────┐
   │BorrowingProtocol │ ──→ Transfers IDRX from treasury
   └──────────────────┘
        │
        ▼
   User receives IDRX (minus 0.5% fee)
        │
        ▼
   User can redeem IDRX to Indonesian Rupiah
        │
        ▼
   To repay: User returns IDRX + withdraws XAUT collateral
```

---

## 📜 Smart Contracts

### Deployed Addresses (Mantle Sepolia)

| Contract | Address | Description |
|----------|---------|-------------|
| **MockIDRX** | [`0xf0C848387950609a3F97e3d67363C46562aD0e28`](https://explorer.sepolia.mantle.xyz/address/0xf0C848387950609a3F97e3d67363C46562aD0e28) | Indonesian Rupiah Stablecoin (Mock) |
| **MockUSDC** | [`0xc76AfD7BAd35e66A6146564DDc391C97300c642b`](https://explorer.sepolia.mantle.xyz/address/0xc76AfD7BAd35e66A6146564DDc391C97300c642b) | USD Coin (Mock) |
| **XAUT** | [`0xab8c0a0a773356A0843567b89E6e4330FDa7B9D6`](https://explorer.sepolia.mantle.xyz/address/0xab8c0a0a773356A0843567b89E6e4330FDa7B9D6) | Tokenized Gold (Mock) |
| **IdentityRegistry** | [`0x28532929e2A67Dba781391bA0f7663b0cADA655F`](https://explorer.sepolia.mantle.xyz/address/0x28532929e2A67Dba781391bA0f7663b0cADA655F) | KYC Verification |
| **UniswapV2Factory** | [`0x55c3D72C2F35A157ee154Bb37B7dDC9be0132BBf`](https://explorer.sepolia.mantle.xyz/address/0x55c3D72C2F35A157ee154Bb37B7dDC9be0132BBf) | DEX Factory |
| **UniswapV2Router** | [`0x7064Acd14aD0a4b75997C0CcBAD2C89DadA6df69`](https://explorer.sepolia.mantle.xyz/address/0x7064Acd14aD0a4b75997C0CcBAD2C89DadA6df69) | DEX Router |
| **SwapRouter** | [`0x8980c7477E091E06f34a418c9fc923D1df849734`](https://explorer.sepolia.mantle.xyz/address/0x8980c7477E091E06f34a418c9fc923D1df849734) | IDRX↔XAUT Router |
| **BorrowingProtocolV2** | [`0xb38139e077621421eba724008bB33C10996E6435`](https://explorer.sepolia.mantle.xyz/address/0xb38139e077621421eba724008bB33C10996E6435) | Cash Loan Protocol |

### Contract Overview

```
src/
├── BorrowingProtocolV2.sol # Cash loan protocol (XAUT collateral → IDRX loan)
├── SwapRouter.sol          # Routes swaps: IDRX ↔ USDC ↔ XAUT
├── IdentityRegistry.sol    # On-chain KYC management
├── XAUT.sol                # Tokenized gold with transfer restrictions
├── MockIDRX.sol            # Mock Indonesian Rupiah stablecoin (with burn)
├── MockUSDC.sol            # Mock USDC for testing
└── interfaces/
    └── IIdentityRegistry.sol
```

### Key Contract Features

#### BorrowingProtocolV2 (Cash Loan)
- **Instant IDRX loans** using XAUT collateral
- **Flexible LTV ratios** (up to 75% safe limit)
- **0.5% borrow fee** on each loan
- **Automatic LTV monitoring** for user safety
- **Repay and withdraw anytime** - no lock-up period
- **Only verified users** can borrow (KYC required)
- **Treasury-backed** lending from pre-funded IDRX pool

**Key Functions**:
- `depositAndBorrow(collateral, borrowAmount)` - One-click collateral deposit + borrow
- `repayAndWithdraw(repayAmount, withdrawAmount)` - One-click repay + withdraw collateral
- `getLTV(user)` - Check current loan-to-value ratio
- `getMaxBorrow(collateralAmount)` - Calculate maximum borrowable amount

**Safety Parameters**:
- MAX_LTV: 75% (safe borrowing limit)
- WARNING_LTV: 80% (warning zone)
- LIQUIDATION_LTV: 90% (liquidation threshold)

---

#### MockIDRX (Enhanced ERC20)
- Standard ERC20 stablecoin representing Indonesian Rupiah
- **Burn functions** for fiat redemption flow:
  - `burn(amount)` - Standard burn
  - `burnFrom(account, amount)` - Burn with allowance
  - `burnWithAccountNumber(amount, accountNumber)` - **Critical for redeem flow**
- Emits `BurnWithAccountNumber` event for backend integration
- Compatible with IDRX.org API for fiat conversion

---

#### SwapRouter
- Single transaction: IDRX → USDC → XAUT (or reverse)
- Slippage protection with `amountOutMin`
- Deadline protection to prevent stale transactions
- Emits detailed swap events

#### IdentityRegistry
- Admin-controlled KYC verification
- Batch registration support
- Multi-admin capability
- Required for XAUT transfers and vault operations

---

### Run Specific Tests

```bash
# All tests
forge test

# Verbose output
forge test -vvv

# Specific contract
forge test --match-contract GoldVaultTest

# Specific test
forge test --match-test testDeposit

# Gas report
forge test --gas-report
```

---

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) (v1.5.0 or later)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/YohanesVito/auroom-sc.git
cd auroom-sc

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### Environment Setup

Create a `.env` file:

```env
# Private key for deployment
PRIVATE_KEY=your_private_key_here

# RPC URLs
MANTLE_SEPOLIA_RPC=https://rpc.sepolia.mantle.xyz
MANTLE_MAINNET_RPC=https://rpc.mantle.xyz

# Deployer address
DEPLOYER=your_deployer_address

# Contract addresses (will be filled after deployment)
MOCK_IDRX=
MOCK_USDC=
XAUT=
IDENTITY_REGISTRY=
UNISWAP_FACTORY=
UNISWAP_ROUTER=
BORROWING_PROTOCOL_V2=
SWAP_ROUTER=

# Treasury
TREASURY=your_treasury_address

# Block explorer API key
MANTLE_API_KEY=your_api_key_here
```

### Deployment

See `script/mantle/deployment/README.md` for detailed deployment instructions.

```bash
# Deploy contracts to Mantle Sepolia (run in order)
forge script script/mantle/deployment/Deploy01_MockIDRX.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast

# ... continue with Deploy02 through Deploy09

# Verify all contracts after deployment
./script/mantle/post-deployment/verify-all.sh
```

### Post-Deployment Setup

Run the post-deployment scripts in order:

```bash
# 1. Register contracts in KYC
forge script script/mantle/post-deployment/Setup01_RegisterKYC.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast

# 2. Mint IDRX to Treasury
forge script script/mantle/post-deployment/Setup02_MintTreasury.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast

# 3. Approve Protocol to spend Treasury IDRX
forge script script/mantle/post-deployment/Setup03_ApproveProtocol.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast
```

---

## 📁 Project Structure

```
auroom-sc/
├── src/                    # Smart contract source files
│   ├── BorrowingProtocolV2.sol
│   ├── SwapRouter.sol
│   ├── IdentityRegistry.sol
│   ├── XAUT.sol
│   ├── MockIDRX.sol
│   ├── MockUSDC.sol
│   └── interfaces/
├── test/                   # Test files
│   ├── BorrowingProtocolV2.t.sol
│   ├── SwapRouter.t.sol
│   ├── IdentityRegistry.t.sol
│   ├── Integration.t.sol
│   └── ...
├── script/                 # Deployment scripts
│   ├── base/               # Base Sepolia (legacy)
│   └── mantle/             # Mantle Sepolia (active)
│       ├── deployment/
│       ├── post-deployment/
│       └── helper/
├── lib/                    # Dependencies (git submodules)
│   ├── openzeppelin-contracts/
│   ├── uniswap-v2-core/
│   └── uniswap-v2-periphery/
├── deployments/            # Deployment records
├── foundry.toml            # Foundry configuration
└── README.md
```

---

## ⚙️ Configuration

### foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.30"
optimizer = true
optimizer_runs = 200

[profile.uniswap]
solc = "0.6.6"
optimizer_runs = 999999
```

### Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| OpenZeppelin | 5.x | ERC20, ERC4626, Access Control |
| Uniswap V2 Core | - | AMM pairs |
| Uniswap V2 Periphery | - | Router |

---

## 🔐 Security Considerations

### Implemented Security Features

- ✅ **Slippage Protection**: All swaps have `amountOutMin` parameter
- ✅ **Deadline Protection**: Transactions expire after specified time
- ✅ **Access Control**: Only verified users can interact with XAUT
- ✅ **Reentrancy Guards**: Protected vault operations
- ✅ **Input Validation**: All user inputs are validated

### Audit Status

⏳ **Pending**: Professional audit planned for mainnet launch

Current status:
- ✅ Internal testing complete (106/106 tests)
- ✅ Testnet deployment verified
- ⏳ External audit in progress

---

## 🗺️ Roadmap

- [x] Core contracts development
- [x] Comprehensive test suite
- [x] **Mantle Sepolia deployment** ✨
- [x] BorrowingProtocolV2 (Cash Loan) implementation
- [x] IDRX burn functions for redeem flow
- [x] Frontend integration
- [ ] Backend API for IDRX redemption (in progress)
- [ ] Frontend redeem modal integration
- [ ] Security audit
- [ ] Mainnet deployment
- [ ] Multi-chain expansion

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Mantle Network** - L2 Infrastructure
- **IDRX.org** - Indonesian Rupiah Stablecoin & API Integration
- **Tether Gold (XAUT)** - Tokenized gold concept
- **OpenZeppelin** - Secure contract libraries
- **Uniswap** - AMM protocol

---

## 📬 Contact

**Apple Bites** - [@YohanesVito](https://github.com/YohanesVito)

Project Links:
- Smart Contracts: [https://github.com/auroom-mantle/auroom-mantle-sc](https://github.com/auroom-mantle/auroom-mantle-sc)
- Frontend: [https://github.com/auroom-mantle/auroom-mantle-fe](https://github.com/auroom-mantle/auroom-mantle-fe)
- Backend: [https://github.com/auroom-mantle/auroom-mantle-be](https://github.com/auroom-mantle/auroom-mantle-be)

---

<div align="center">

**Built with ❤️ on Mantle Sepolia Network**

[⬆ Back to Top](#-auroom-protocol---smart-contracts)

</div>

