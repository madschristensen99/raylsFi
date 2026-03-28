// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/public-chain/MockSPY.sol";
import "../contracts/public-chain/LendingPool.sol";
import "../contracts/public-chain/UnifiedVault.sol";
import "../contracts/public-chain/YieldRouter.sol";
import "../contracts/public-chain/ProtocolTreasury.sol";
import "../contracts/public-chain/ShareToken.sol";
import "../contracts/public-chain/AIAttestation.sol";

contract DeployPublicChain is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying to Rayls Public Chain...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        MockSPY spyToken = new MockSPY();
        console.log("MockSPY deployed at:", address(spyToken));
        
        LendingPool lendingPool = new LendingPool(address(spyToken));
        console.log("LendingPool deployed at:", address(lendingPool));
        
        UnifiedVault vault = new UnifiedVault(address(spyToken));
        console.log("UnifiedVault deployed at:", address(vault));
        
        ProtocolTreasury treasury = new ProtocolTreasury(address(spyToken));
        console.log("ProtocolTreasury deployed at:", address(treasury));
        
        YieldRouter yieldRouter = new YieldRouter(
            address(spyToken),
            address(lendingPool),
            address(vault),
            address(treasury)
        );
        console.log("YieldRouter deployed at:", address(yieldRouter));
        
        vault.setYieldRouter(address(yieldRouter));
        console.log("YieldRouter set in UnifiedVault");
        
        ShareToken shareToken = new ShareToken(
            "RaylsFi SPY Shares",
            "rfSPY",
            bytes32(0),
            "Fractional SPY shares on RaylsFi"
        );
        console.log("ShareToken deployed at:", address(shareToken));
        
        AIAttestation aiAttestation = new AIAttestation();
        console.log("AIAttestation deployed at:", address(aiAttestation));
        
        uint256 initialMint = 100000 * 10**18;
        spyToken.mint(vm.addr(deployerPrivateKey), initialMint);
        console.log("Minted", initialMint / 10**18, "SPY tokens to deployer");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("MockSPY:", address(spyToken));
        console.log("LendingPool:", address(lendingPool));
        console.log("UnifiedVault:", address(vault));
        console.log("YieldRouter:", address(yieldRouter));
        console.log("ProtocolTreasury:", address(treasury));
        console.log("ShareToken:", address(shareToken));
        console.log("AIAttestation:", address(aiAttestation));
    }
}
