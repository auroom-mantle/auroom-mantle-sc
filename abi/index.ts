/**
 * AuRoom Protocol - Contract ABIs and Addresses
 * Generated: December 20, 2024
 * Network: Mantle Sepolia (Chain ID: 5003)
 */

// Import ABIs
import MockIDRXABI from './MockIDRX.json';
import MockUSDCABI from './MockUSDC.json';
import XAUTABI from './XAUT.json';
import IdentityRegistryABI from './IdentityRegistry.json';
import UniswapV2FactoryABI from './UniswapV2Factory.json';
import UniswapV2Router02ABI from './UniswapV2Router02.json';
import UniswapV2PairABI from './UniswapV2Pair.json';
import SwapRouterABI from './SwapRouter.json';
import GoldVaultABI from './GoldVault.json';

// Import addresses
import addresses from './addresses.json';

// Export ABIs
export const ABIs = {
  MockIDRX: MockIDRXABI,
  MockUSDC: MockUSDCABI,
  XAUT: XAUTABI,
  IdentityRegistry: IdentityRegistryABI,
  UniswapV2Factory: UniswapV2FactoryABI,
  UniswapV2Router02: UniswapV2Router02ABI,
  UniswapV2Pair: UniswapV2PairABI,
  SwapRouter: SwapRouterABI,
  GoldVault: GoldVaultABI,
};

// Export addresses
export const ADDRESSES = addresses;

// Export Mantle Sepolia addresses for convenience
export const MANTLE_SEPOLIA = addresses.mantleSepolia;

// Export contract configurations (ABI + Address)
export const CONTRACTS = {
  mantleSepolia: {
    MockIDRX: {
      address: MANTLE_SEPOLIA.tokens.MockIDRX,
      abi: ABIs.MockIDRX,
    },
    MockUSDC: {
      address: MANTLE_SEPOLIA.tokens.MockUSDC,
      abi: ABIs.MockUSDC,
    },
    XAUT: {
      address: MANTLE_SEPOLIA.tokens.XAUT,
      abi: ABIs.XAUT,
    },
    IdentityRegistry: {
      address: MANTLE_SEPOLIA.infrastructure.IdentityRegistry,
      abi: ABIs.IdentityRegistry,
    },
    UniswapV2Factory: {
      address: MANTLE_SEPOLIA.infrastructure.UniswapV2Factory,
      abi: ABIs.UniswapV2Factory,
    },
    UniswapV2Router02: {
      address: MANTLE_SEPOLIA.infrastructure.UniswapV2Router02,
      abi: ABIs.UniswapV2Router02,
    },
    SwapRouter: {
      address: MANTLE_SEPOLIA.protocol.SwapRouter,
      abi: ABIs.SwapRouter,
    },
    GoldVault: {
      address: MANTLE_SEPOLIA.protocol.GoldVault,
      abi: ABIs.GoldVault,
    },
    // Liquidity Pairs
    Pairs: {
      IDRX_USDC: {
        address: MANTLE_SEPOLIA.pairs.IDRX_USDC,
        abi: ABIs.UniswapV2Pair,
      },
      XAUT_USDC: {
        address: MANTLE_SEPOLIA.pairs.XAUT_USDC,
        abi: ABIs.UniswapV2Pair,
      },
    },
  },
};

// Export types for TypeScript
export type ContractName = keyof typeof ABIs;
export type NetworkName = keyof typeof addresses;
