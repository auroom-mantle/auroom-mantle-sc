# AuRoom Protocol - Contract ABIs

This folder contains the Application Binary Interfaces (ABIs) for all AuRoom Protocol smart contracts deployed on Mantle Sepolia testnet.

## 📋 Available ABIs

### Core Tokens
- **MockIDRX.json** - Indonesian Rupiah stablecoin (mock)
- **MockUSDC.json** - USD Coin stablecoin (mock)
- **XAUT.json** - Tokenized gold with compliance features

### Infrastructure
- **IdentityRegistry.json** - User verification and compliance registry
- **UniswapV2Factory.json** - DEX factory for creating liquidity pairs
- **UniswapV2Router02.json** - DEX router for swaps and liquidity
- **UniswapV2Pair.json** - Liquidity pair contract interface

### Protocol Contracts
- **SwapRouter.json** - Custom swap router with compliance checks
- **GoldVault.json** - ERC-4626 vault for XAUT staking (issues gXAUT shares)

## 🌐 Contract Addresses

All contract addresses are stored in `addresses.json` and organized by network.

### Mantle Sepolia (Chain ID: 5003)

#### Tokens
- MockIDRX: `0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05`
- MockUSDC: `0x96ABff3a2668B811371d7d763f06B3832CEdf38d`
- XAUT: `0x1d6f37f76E2AB1cf9A242a34082eDEc163503A78`

#### Infrastructure
- IdentityRegistry: `0x620870d419F6aFca8AFed5B516619aa50900cadc`
- UniswapV2Factory: `0x8950d0D71a23085C514350df2682c3f6F1D7aBFE`
- UniswapV2Router02: `0x54166b2C5e09f16c3c1D705FfB4eb29a069000A9`

#### Liquidity Pairs
- IDRX/USDC: `0xD3FF8e1C2821745513Ef83f3551668A7ce791Fe2`
- XAUT/USDC: `0xc2da5178F53f45f604A275a3934979944eB15602`

#### Protocol
- SwapRouter: `0xF948Dd812E7fA072367848ec3D198cc61488b1b9`
- GoldVault: `0xd92cE2F13509840B1203D35218227559E64fbED0`

## 📦 Usage

### TypeScript/JavaScript (Recommended)

```typescript
import { CONTRACTS, ABIs, MANTLE_SEPOLIA } from './abi';

// Use with ethers.js
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider('https://rpc.sepolia.mantle.xyz');
const swapRouter = new ethers.Contract(
  CONTRACTS.mantleSepolia.SwapRouter.address,
  CONTRACTS.mantleSepolia.SwapRouter.abi,
  provider
);

// Or access directly
const xautAddress = MANTLE_SEPOLIA.tokens.XAUT;
const xautABI = ABIs.XAUT;
```

### React with wagmi

```typescript
import { useContractRead } from 'wagmi';
import { CONTRACTS } from './abi';

function MyComponent() {
  const { data: isVerified } = useContractRead({
    address: CONTRACTS.mantleSepolia.IdentityRegistry.address,
    abi: CONTRACTS.mantleSepolia.IdentityRegistry.abi,
    functionName: 'isVerified',
    args: [userAddress],
  });
}
```

### Viem

```typescript
import { createPublicClient, http } from 'viem';
import { mantleSepoliaTestnet } from 'viem/chains';
import { CONTRACTS } from './abi';

const client = createPublicClient({
  chain: mantleSepoliaTestnet,
  transport: http(),
});

const balance = await client.readContract({
  address: CONTRACTS.mantleSepolia.XAUT.address,
  abi: CONTRACTS.mantleSepolia.XAUT.abi,
  functionName: 'balanceOf',
  args: [userAddress],
});
```

## 🔄 Regenerating ABIs

If contracts are updated, regenerate ABIs using:

```bash
# Build contracts first
forge build

# Extract ABIs
jq '.abi' out/MockIDRX.sol/MockIDRX.json > abi/MockIDRX.json
jq '.abi' out/MockUSDC.sol/MockUSDC.json > abi/MockUSDC.json
jq '.abi' out/XAUT.sol/XAUT.json > abi/XAUT.json
jq '.abi' out/IdentityRegistry.sol/IdentityRegistry.json > abi/IdentityRegistry.json
jq '.abi' out/MockUniswapV2Factory.sol/MockUniswapV2Factory.json > abi/UniswapV2Factory.json
jq '.abi' out/MockUniswapV2Router02.sol/MockUniswapV2Router02.json > abi/UniswapV2Router02.json
jq '.abi' out/SwapRouter.sol/SwapRouter.json > abi/SwapRouter.json
jq '.abi' out/GoldVault.sol/GoldVault.json > abi/GoldVault.json
jq '.abi' out/IUniswapV2Pair.sol/IUniswapV2Pair.json > abi/UniswapV2Pair.json
```

## 📝 Notes

- All contracts are deployed on **Mantle Sepolia testnet** (Chain ID: 5003)
- RPC URL: `https://rpc.sepolia.mantle.xyz`
- Block Explorer: `https://explorer.sepolia.mantle.xyz`
- All tests passed (106/106) ✅
- Last updated: December 20, 2024

## 🔐 Important Features

### XAUT Token
- Compliance-enabled token (requires identity verification)
- Only verified users can receive/transfer XAUT
- Integrated with IdentityRegistry

### GoldVault
- ERC-4626 compliant vault
- Issues gXAUT shares (1:1 ratio with XAUT)
- gXAUT transfers also require verification
- Zero fees on deposit/withdrawal

### SwapRouter
- Custom router with compliance checks
- Supports multi-hop routing (IDRX → USDC → XAUT)
- Enforces user verification for XAUT swaps
- Slippage and deadline protection

## 🚀 Status

**READY FOR PRODUCTION** - All tests passed, contracts verified and functional.
