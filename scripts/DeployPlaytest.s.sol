// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/public-chain/PlaytestVault.sol";

contract DeployPlaytest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy PlaytestVault
        PlaytestVault vault = new PlaytestVault();
        
        console.log("PlaytestVault deployed at:", address(vault));
        
        vm.stopBroadcast();
    }
}
