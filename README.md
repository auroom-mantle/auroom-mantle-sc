# 🏆 AuRoom Protocol - Smart Contracts

<div align="center">

![AuRoom Banner](https://img.shields.io/badge/AuRoom-Protocol-gold?style=for-the-badge&logo=ethereum&logoColor=white)

**From Rupiah to Yield-Bearing Gold**

[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-363636?style=flat-square&logo=solidity)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-1.5.0-orange?style=flat-square)](https://getfoundry.sh/)
[![Base](https://img.shields.io/badge/Base-Sepolia-blue?style=flat-square)](https://base.org/)
[![Tests](https://img.shields.io/badge/Tests-106%2F106%20Passing-brightgreen?style=flat-square)](./test)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](./LICENSE)

[Live Demo](https://auroom-testnet.vercel.app) • [Frontend Repo](https://github.com/AuRoom-Base/auroom-base-fe) • [Backend Repo](https://github.com/AuRoom-Base/auroom-base-be) • [Documentation](#-documentation)

</div>

---

## 📖 Overview

**AuRoom** is a Real World Asset (RWA) protocol that enables Indonesian users to access instant cash loans in IDRX (Indonesian Rupiah stablecoin) using tokenized gold (XAUT) as collateral, with integrated fiat redemption to convert IDRX back to Indonesian Rupiah (IDR).

### The Problem

| Traditional Gold Investment | Regular DEX |
|----------------------------|-------------|
| ❌ High minimum investment | ❌ Swap only, no yield |
| ❌ Storage fees | ❌ Assets sit idle |
| ❌ Illiquid (limited hours) | ❌ Manual management |
| ❌ No yield generation | ❌ Just tokens, no system |

---

## ✨ Key Features

- 🔄 **Seamless Swap**: IDRX → USDC → XAUT in one transaction
- 💰 **Cash Loan**: Borrow IDRX (Indonesian Rupiah) using XAUT (gold) as collateral
- 🏦 **Fiat Redemption**: Convert IDRX to IDR (Indonesian fiat) via integrated IDRX.org API
- 🪪 **KYC Compliance**: On-chain identity verification (ERC-3643 inspired)
- ⚡ **Low Fees**: Built on Base L2 for minimal gas costs (0.5% borrow fee)
- 🔒 **Security**: Slippage protection, LTV limits, access control

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
           │                          └─────────┘
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

### Deployed Addresses (Base Sepolia)

| Contract | Address | Description |
|----------|---------|-------------|
| **MockIDRX** | [`0x998ceb700e57f535873D189a6b1B7E2aA8C594EB`](https://sepolia.basescan.org/address/0x998ceb700e57f535873D189a6b1B7E2aA8C594EB) | Indonesian Rupiah Stablecoin (Mock) |
| **MockUSDC** | [`0xCd88C2886A1958BA36238A070e71B51CF930b44d`](https://sepolia.basescan.org/address/0xCd88C2886A1958BA36238A070e71B51CF930b44d) | USD Coin (Mock) |
| **XAUT** | [`0x56EeDF50c3C4B47Ca9762298B22Cb86468f834FC`](https://sepolia.basescan.org/address/0x56EeDF50c3C4B47Ca9762298B22Cb86468f834FC) | Tokenized Gold (Mock) |
| **IdentityRegistry** | [`0xA8F2b8180caFC670f4a24114FDB9c50361038857`](https://sepolia.basescan.org/address/0xA8F2b8180caFC670f4a24114FDB9c50361038857) | KYC Verification |
| **UniswapV2Factory** | [`0xDb198BEaccC55934062Be9AAEdce332c40A1f1Ed`](https://sepolia.basescan.org/address/0xDb198BEaccC55934062Be9AAEdce332c40A1f1Ed) | DEX Factory |
| **UniswapV2Router** | [`0x620870d419F6aFca8AFed5B516619aa50900cadc`](https://sepolia.basescan.org/address/0x620870d419F6aFca8AFed5B516619aa50900cadc) | DEX Router |
| **SwapRouter** | [`0x41c7215F0538200013F428732900bC581015c50e`](https://sepolia.basescan.org/address/0x41c7215F0538200013F428732900bC581015c50e) | IDRX↔XAUT Router |
| **BorrowingProtocolV2** | [`0x3A1229F6D51940DBa65710F9F6ab0296FD56718B`](https://sepolia.basescan.org/address/0x3A1229F6D51940DBa65710F9F6ab0296FD56718B) | Cash Loan Protocol |

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
BASE_SEPOLIA_RPC=https://sepolia.base.org
BASE_MAINNET_RPC=https://mainnet.base.org

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
BASESCAN_API_KEY=your_api_key_here
```

### Deployment

See `script/base/deployment/README.md` for detailed deployment instructions.

```bash
# Deploy contracts to Base Sepolia (run in order)
forge script script/base/deployment/Deploy01_MockIDRX.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify

# ... continue with Deploy02 through Deploy09

# Verify contracts on Basescan
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
  --chain-id 84532 \
  --verifier blockscout \
  --verifier-url https://base-sepolia.blockscout.com/api
```

### Post-Deployment Setup

Run the post-deployment scripts in order:

```bash
# 1. Register contracts in KYC
forge script script/base/post-deployment/Setup01_RegisterKYC.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast

# 2. Mint IDRX to Treasury
forge script script/base/post-deployment/Setup02_MintTreasury.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast

# 3. Approve Protocol to spend Treasury IDRX
forge script script/base/post-deployment/Setup03_ApproveProtocol.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast
```

---

## 📁 Project Structure

```
auroom-sc/
├── src/                    # Smart contract source files
│   ├── GoldVault.sol
│   ├── SwapRouter.sol
│   ├── IdentityRegistry.sol
│   ├── XAUT.sol
│   ├── MockIDRX.sol
│   ├── MockUSDC.sol
│   └── interfaces/
├── test/                   # Test files
│   ├── GoldVault.t.sol
│   ├── SwapRouter.t.sol
│   ├── IdentityRegistry.t.sol
│   ├── Integration.t.sol
│   └── ...
├── script/                 # Deployment scripts
│   └── Deploy.s.sol
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
- [x] Lisk Sepolia deployment
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

- **Base Network** - L2 Infrastructure
- **IDRX.org** - Indonesian Rupiah Stablecoin & API Integration
- **Tether Gold (XAUT)** - Tokenized gold concept
- **OpenZeppelin** - Secure contract libraries
- **Uniswap** - AMM protocol

---

## 📬 Contact

**Apple Bites** - [@YohanesVito](https://github.com/YohanesVito)

Project Links:
- Smart Contracts: [https://github.com/YohanesVito/auroom-base-sc](https://github.com/YohanesVito/auroom-base-sc)
- Frontend: [https://github.com/AuRoom-Base/auroom-base-fe](https://github.com/AuRoom-Base/auroom-base-fe)
- Backend: [https://github.com/AuRoom-Base/auroom-base-be](https://github.com/AuRoom-Base/auroom-base-be)

---

<div align="center">

**Built with ❤️ on Base Sepolia Network**

[⬆ Back to Top](#-auroom-protocol---smart-contracts)

</div>
