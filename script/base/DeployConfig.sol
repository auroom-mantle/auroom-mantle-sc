// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title DeployConfig
 * @notice Configuration constants for deployment across different networks
 */
library DeployConfig {
    // Network identifiers
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    // Initial token amounts
    uint256 constant INITIAL_IDRX = 1_000_000_000 * 1e6; // 1 billion IDRX
    uint256 constant INITIAL_USDC = 10_000_000 * 1e6;     // 10 million USDC
    uint256 constant INITIAL_XAUT = 100 * 1e6;            // 100 XAUT

    /**
     * @notice Get Uniswap V2 Router address for the current network
     * @param chainId The chain ID to get router for
     * @return router The Uniswap V2 Router address
     */
    function getUniswapRouter(uint256 chainId) internal pure returns (address router) {
        if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            // Base Sepolia - Use deployed mock router
            router = 0x0000000000000000000000000000000000000000; // Fill after deployment
        } else if (chainId == BASE_MAINNET_CHAIN_ID) {
            // Base Mainnet - Uniswap V2 Router (if available) or BaseSwap
            router = 0x0000000000000000000000000000000000000000; // TODO: Update with actual address
        } else if (chainId == LOCAL_CHAIN_ID) {
            // Local testnet - deploy mock router or use test address
            router = 0x0000000000000000000000000000000000000000; // Will be deployed in test
        } else {
            revert("DeployConfig: Unsupported chain ID");
        }
    }

    /**
     * @notice Get network name from chain ID
     * @param chainId The chain ID
     * @return name The network name
     */
    function getNetworkName(uint256 chainId) internal pure returns (string memory name) {
        if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            name = "base-sepolia";
        } else if (chainId == BASE_MAINNET_CHAIN_ID) {
            name = "base-mainnet";
        } else if (chainId == LOCAL_CHAIN_ID) {
            name = "localhost";
        } else {
            name = "unknown";
        }
    }

    /**
     * @notice Check if current network is testnet
     * @param chainId The chain ID
     * @return isTestnet True if testnet
     */
    function isTestnet(uint256 chainId) internal pure returns (bool) {
        return chainId == BASE_SEPOLIA_CHAIN_ID || chainId == LOCAL_CHAIN_ID;
    }
}
