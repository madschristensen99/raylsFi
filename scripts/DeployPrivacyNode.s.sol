// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/privacy-node/UserLedger.sol";
import "../contracts/privacy-node/PrivacyGovernor.sol";

contract DeployPrivacyNode is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying to Rayls Privacy Node...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        UserLedger userLedger = new UserLedger();
        console.log("UserLedger deployed at:", address(userLedger));
        
        PrivacyGovernor privacyGovernor = new PrivacyGovernor();
        console.log("PrivacyGovernor deployed at:", address(privacyGovernor));
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("UserLedger:", address(userLedger));
        console.log("PrivacyGovernor:", address(privacyGovernor));
    }
}
