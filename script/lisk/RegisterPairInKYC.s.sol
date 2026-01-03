// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";

interface IIdentityRegistry {
    function registerIdentity(address user) external;
}

contract RegisterPairInKYC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address identityRegistry = vm.envAddress("IDENTITY_REGISTRY");
        
        // Pair address that Factory is creating (IDRX/USDC pair address - shared)
        address pairAddress = 0x478FA3880F8474E50ECEDDA71a1D56d5560b1E3f;
        
        console.log("Registering pair in IdentityRegistry...");
        console.log("Pair:", pairAddress);
        console.log("Registry:", identityRegistry);
        
        vm.startBroadcast(deployerPrivateKey);
        
        IIdentityRegistry(identityRegistry).registerIdentity(pairAddress);
        
        vm.stopBroadcast();
        
        console.log("Successfully registered!");
    }
}
