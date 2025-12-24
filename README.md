# 🏆 AuRoom Protocol - Smart Contracts

<div align="center">

![AuRoom Banner](https://img.shields.io/badge/AuRoom-Protocol-gold?style=for-the-badge&logo=ethereum&logoColor=white)

**From Rupiah to Yield-Bearing Gold**

[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-363636?style=flat-square&logo=solidity)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-1.5.0-orange?style=flat-square)](https://getfoundry.sh/)
[![Mantle](https://img.shields.io/badge/Mantle-Sepolia-blue?style=flat-square)](https://www.mantle.xyz/)
[![Tests](https://img.shields.io/badge/Tests-106%2F106%20Passing-brightgreen?style=flat-square)](./test)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](./LICENSE)

[Live Demo](https://auroom-testnet.vercel.app) • [Frontend Repo](https://github.com/YohanesVito/auroom-fe) • [Documentation](#-documentation)

</div>

---

## 📖 Overview

**AuRoom** is a Real World Asset (RWA) protocol that enables Indonesian users to convert their local currency (IDRX) into tokenized gold (XAUT) and earn yield through an ERC-4626 vault system.

### The Problem

| Traditional Gold Investment | Regular DEX |
|----------------------------|-------------|
| ❌ High minimum investment | ❌ Swap only, no yield |
| ❌ Storage fees | ❌ Assets sit idle |
| ❌ Illiquid (limited hours) | ❌ Manual management |
| ❌ No yield generation | ❌ Just tokens, no system |

### The AuRoom Solution

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   REGULAR DEX:                                                  │
│   IDRX ──→ XAUT ──→ 💤 Idle (0% yield)                         │
│                                                                 │
│   AUROOM:                                                       │
│   IDRX ──→ XAUT ──→ GoldVault ──→ gXAUT ──→ 📈 Earning Yield   │
│                                                                 │
│   "Not just a swap. A complete gold investment system."         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

- 🔄 **Seamless Swap**: IDRX → USDC → XAUT in one transaction
- 🏦 **ERC-4626 Vault**: Industry-standard yield-bearing vault
- 📈 **Yield Generation**: Earn from liquidity provision fees (0.3%)
- 🪪 **KYC Compliance**: On-chain identity verification (ERC-3643 inspired)
- ⚡ **Low Fees**: Built on Mantle L2 for minimal gas costs
- 🔒 **Security**: Slippage protection, deadline checks, access control

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
       │   Swap   │   │  Deposit │   │  Redeem  │
       │IDRX→XAUT │   │XAUT→gXAUT│   │gXAUT→XAUT│
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            ▼              ▼              ▼
     ┌────────────┐  ┌───────────┐  ┌───────────┐
     │ SwapRouter │  │ GoldVault │  │ GoldVault │
     │            │  │ (ERC-4626)│  │ (ERC-4626)│
     └─────┬──────┘  └───────────┘  └───────────┘
           │
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

### How Yield is Generated

```
User deposits XAUT
        │
        ▼
   ┌─────────┐
   │GoldVault│ ──→ Provides liquidity to XAUT/USDC pool
   └─────────┘
        │
        ▼
   Trading Fees (0.3% per swap)
        │
        ▼
   Fees accumulate in vault
        │
        ▼
   Share price increases
        │
        ▼
   User redeems more XAUT than deposited = PROFIT
```

---

## 📜 Smart Contracts

### Deployed Addresses (Mantle Sepolia)

| Contract | Address | Description |
|----------|---------|-------------|
| **IDRX** | `0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05` | Indonesian Rupiah Stablecoin (Mock) |
| **USDC** | `0x96ABff3a2668B811371d7d763f06B3832CEdf38d` | USD Coin (Mock) |
| **XAUT** | `0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78` | Tokenized Gold (Mock) |
| **IdentityRegistry** | `0x620870d419F6aFca8AFed5B516619aa50900cadc` | KYC Verification |
| **UniswapV2Factory** | `0x8950d0D71a23085C514350df2682c3f6F1D7aBFE` | DEX Factory |
| **UniswapV2Router** | `0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9` | DEX Router |
| **IDRX/USDC Pair** | `0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2` | Liquidity Pool |
| **XAUT/USDC Pair** | `0xc2da5178F53f45f604A275a3934979944eB15602` | Liquidity Pool |
| **SwapRouter** | `0xF948Dd812E7fA072367848ec3D198cc61488b1b9` | IDRX↔XAUT Router |
| **GoldVault** | `0xd92cE2F13509840B1203D35218227559E64fbED0` | ERC-4626 Yield Vault |

### Contract Overview

```
src/
├── GoldVault.sol          # ERC-4626 yield-bearing vault for XAUT
├── SwapRouter.sol         # Routes swaps: IDRX ↔ USDC ↔ XAUT
├── IdentityRegistry.sol   # On-chain KYC management
├── XAUT.sol               # Tokenized gold with transfer restrictions
├── MockIDRX.sol           # Mock Indonesian Rupiah stablecoin
├── MockUSDC.sol           # Mock USDC for testing
├── WMNT.sol               # Wrapped Mantle token
└── interfaces/
    └── IIdentityRegistry.sol
```

### Key Contract Features

#### GoldVault (ERC-4626)
- Deposit XAUT, receive gXAUT shares
- Share price increases as yield accumulates
- No lock-up period - withdraw anytime
- Only verified users can deposit/withdraw

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

## 🧪 Testing

### Test Results: 106/106 Passing ✅

```bash
forge test
```

```
[⠊] Compiling...
[⠒] Compiling 1 files with Solc 0.8.30

Ran 106 tests for 7 test suites

✅ GoldVaultTest - 22 tests passed
✅ IdentityRegistryTest - 15 tests passed  
✅ XAUTTest - 14 tests passed
✅ SwapRouterTest - 18 tests passed
✅ IntegrationTest - 19 tests passed
✅ DEXTest - 10 tests passed
✅ SecurityTest - 8 tests passed

Total: 106 passed, 0 failed, 0 skipped
```

### Test Coverage

| Category | Tests | Coverage |
|----------|-------|----------|
| Unit Tests | 69 | Core contract functions |
| Integration Tests | 19 | Multi-contract flows |
| Security Tests | 8 | Access control, edge cases |
| DEX Tests | 10 | Liquidity, swaps |

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
MANTLE_TESTNET_RPC=https://rpc.sepolia.mantle.xyz
MANTLE_MAINNET_RPC=https://rpc.mantle.xyz

# Explorer API (for verification)
MANTLE_API_KEY=your_api_key_here
```

### Deployment

```bash
# Deploy to Mantle Sepolia
forge script script/Deploy.s.sol --rpc-url $MANTLE_TESTNET_RPC --broadcast

# Verify contracts
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain mantle-sepolia
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
- [x] Mantle Sepolia deployment
- [x] Frontend integration
- [ ] Security audit
- [ ] Mainnet deployment
- [ ] Additional yield strategies
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
- **IDRX** - Indonesian Rupiah Stablecoin inspiration
- **Tether Gold (XAUT)** - Tokenized gold concept
- **OpenZeppelin** - Secure contract libraries
- **Uniswap** - AMM protocol

---

## 📬 Contact

**Apple Bites** - [@YohanesVito](https://github.com/YohanesVito)

Project Link: [https://github.com/YohanesVito/auroom-sc](https://github.com/YohanesVito/auroom-sc)

---

<div align="center">

**Built with ❤️ for Mantle Global Hackathon 2025**

[⬆ Back to Top](#-auroom-protocol---smart-contracts)

</div>
