// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../../src/WMNT.sol";
import "../../test/mocks/MockUniswapV2Factory.sol";
import "../../test/mocks/MockUniswapV2Router02.sol";
import "../../test/mocks/MockUniswapV2Pair.sol";

/**
 * @title Deploy7_UniswapV2
 * @dev Deploy Uniswap V2 infrastructure to Lisk Sepolia
 * @notice Deploys WMNT, MockFactory, and MockRouter (Solidity 0.8.30 compatible)
 */
contract Deploy7_UniswapV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==============================================");
        console.log("Deploying Uniswap V2 to Lisk Sepolia");
        console.log("==============================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy WMNT
        console.log("1. Deploying WMNT...");
        WMNT wmnt = new WMNT();
        console.log("   WMNT deployed at:", address(wmnt));

        // 2. Deploy MockUniswapV2Factory
        console.log("");
        console.log("2. Deploying MockUniswapV2Factory...");
        MockUniswapV2Factory factory = new MockUniswapV2Factory();
        console.log("   Factory deployed at:", address(factory));

        // Set feeToSetter
        factory.setFeeToSetter(deployer);
        console.log("   FeeToSetter set to:", deployer);

        // Get INIT_CODE_HASH for MockUniswapV2Pair
        bytes memory pairBytecode = type(MockUniswapV2Pair).creationCode;
        bytes32 initCodeHash = keccak256(
            abi.encodePacked(
                pairBytecode,
                abi.encode(address(0), address(0))
            )
        );
        console.log("   INIT_CODE_HASH:");
        console.logBytes32(initCodeHash);

        // 3. Deploy MockUniswapV2Router02
        console.log("");
        console.log("3. Deploying MockUniswapV2Router02...");
        MockUniswapV2Router02 router = new MockUniswapV2Router02(address(factory), address(wmnt));
        console.log("   Router deployed at:", address(router));

        vm.stopBroadcast();

        console.log("");
        console.log("==============================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("==============================================");
        console.log("WMNT:    ", address(wmnt));
        console.log("Factory: ", address(factory));
        console.log("Router:  ", address(router));
        console.log("");
        console.log("Add to .env file:");
        console.log("WMNT=", address(wmnt));
        console.log("UNISWAP_FACTORY=", address(factory));
        console.log("UNISWAP_ROUTER=", address(router));
        console.log("");
        console.log("Verify on Blockscout:");
        console.log("https://sepolia-blockscout.lisk.com/address/", address(wmnt));
        console.log("https://sepolia-blockscout.lisk.com/address/", address(factory));
        console.log("https://sepolia-blockscout.lisk.com/address/", address(router));
        console.log("==============================================");
    }
}
