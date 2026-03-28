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

contract RunPublicChainTests is Script {
    MockSPY public spyToken = MockSPY(0xEc25CE0d80c44cB8370dC71f6D1d4585244212D7);
    LendingPool public lendingPool = LendingPool(0x52892Eae906f502C4E402301cdD13f3123EAD729);
    UnifiedVault public vault = UnifiedVault(0xF418C8CBdC3422b26b28408Dc31aA8B4Eece54CE);
    ProtocolTreasury public treasury = ProtocolTreasury(0x43D1EcF020297Ad344CE740c8E69CE0A2fECB825);
    YieldRouter public yieldRouter = YieldRouter(0xd7Bd1E8531f79A9FB59b3245A37d8c4602c5B96B);
    ShareToken public shareToken = ShareToken(0x3960A2a73B6ABBb69f352A691EF5a9339f763C8c);
    AIAttestation public aiAttestation = AIAttestation(0x5c8cEc43ce559B90ffb4C3F15FAbedE220Cc24c0);
    
    address public user;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        user = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("========================================");
        console.log("RaylsFi Public Chain Integration Tests");
        console.log("========================================");
        console.log("User address:", user);
        console.log("");
        
        test_01_MintSPYTokens();
        test_02_ApproveLendingPool();
        test_03_SupplyToLendingPool();
        test_04_CheckLendingPoolAPY();
        test_05_DepositToYieldRouter();
        test_06_MintShareTokens();
        test_07_RecordAIAttestation();
        test_08_BridgeReceive();
        test_09_WithdrawFromLendingPool();
        test_99_FinalBalances();
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("========================================");
        console.log("All tests completed successfully!");
        console.log("========================================");
    }
    
    function test_01_MintSPYTokens() internal {
        uint256 mintAmount = 50000 * 10**18;
        
        console.log("--- Test 1: Mint SPY Tokens ---");
        console.log("Minting", mintAmount / 10**18, "SPY tokens");
        
        spyToken.mint(user, mintAmount);
        
        uint256 balance = spyToken.balanceOf(user);
        console.log("User SPY balance:", balance / 10**18);
        
        require(balance >= mintAmount, "Mint failed");
        console.log("SUCCESS: Mint successful");
        console.log("");
    }
    
    function test_02_ApproveLendingPool() internal {
        uint256 approvalAmount = 100000 * 10**18;
        
        console.log("--- Test 2: Approve Lending Pool ---");
        console.log("Approving", approvalAmount / 10**18, "SPY tokens");
        
        spyToken.approve(address(lendingPool), approvalAmount);
        
        uint256 allowance = spyToken.allowance(user, address(lendingPool));
        console.log("Allowance:", allowance / 10**18);
        
        require(allowance >= approvalAmount, "Approval failed");
        console.log("SUCCESS: Approval successful");
        console.log("");
    }
    
    function test_03_SupplyToLendingPool() internal {
        uint256 supplyAmount = 5000 * 10**18;
        
        console.log("--- Test 3: Supply to Lending Pool ---");
        console.log("Supplying", supplyAmount / 10**18, "SPY tokens");
        
        lendingPool.supply(supplyAmount);
        
        (uint256 principal, uint256 interest, uint256 total) = lendingPool.getUserBalance(user);
        console.log("Principal:", principal / 10**18);
        console.log("Interest:", interest / 10**18);
        console.log("Total:", total / 10**18);
        
        require(principal >= supplyAmount, "Supply failed");
        console.log("SUCCESS: Supply successful");
        console.log("");
    }
    
    function test_04_CheckLendingPoolAPY() internal view {
        console.log("--- Test 4: Check Lending Pool APY ---");
        
        uint256 apy = lendingPool.getCurrentAPY();
        console.log("Current APY (basis points):", apy);
        console.log("Current APY (percent):", apy / 100);
        
        console.log("SUCCESS: APY check successful");
        console.log("");
    }
    
    function test_05_DepositToYieldRouter() internal {
        uint256 depositAmount = 2000 * 10**18;
        
        console.log("--- Test 6: Deposit to Yield Router ---");
        console.log("Depositing", depositAmount / 10**18, "SPY to YieldRouter");
        
        spyToken.approve(address(yieldRouter), depositAmount);
        yieldRouter.deposit(depositAmount, user);
        
        uint256 userYield = yieldRouter.getUserYield(user);
        console.log("User pending yield:", userYield / 10**18);
        
        console.log("SUCCESS: Deposit to YieldRouter successful");
        console.log("");
    }
    
    function test_06_MintShareTokens() internal {
        uint256 shares = 100 * 10**18;
        
        console.log("--- Test 7: Mint Share Tokens ---");
        console.log("Minting", shares / 10**18, "rfSPY shares");
        
        bytes32 attestationHash = keccak256("Test attestation");
        shareToken.mint(user, shares, attestationHash);
        
        uint256 balance = shareToken.balanceOf(user);
        console.log("Share token balance:", balance / 10**18);
        
        require(balance >= shares, "Share mint failed");
        console.log("SUCCESS: Share token mint successful");
        console.log("");
    }
    
    function test_07_RecordAIAttestation() internal {
        bytes32 assetId = keccak256("AAPL-FRACTIONAL-001");
        string memory attestation = "AI verified: Apple Inc. fractional share ownership";
        
        console.log("--- Test 8: Record AI Attestation ---");
        console.log("Asset ID:", vm.toString(assetId));
        
        bytes memory signature = abi.encodePacked(assetId);
        aiAttestation.postAttestation(assetId, signature, attestation);
        
        bool verified = aiAttestation.verifyAttestation(assetId);
        console.log("Attestation verified:", verified);
        
        require(verified, "Attestation failed");
        console.log("SUCCESS: AI attestation successful");
        console.log("");
    }
    
    function test_08_BridgeReceive() internal {
        uint256 bridgeAmount = 500 * 10**18;
        
        console.log("--- Test 9: Bridge Receive ---");
        console.log("Simulating bridge receive of", bridgeAmount / 10**18, "SPY");
        
        spyToken.approve(address(vault), bridgeAmount);
        vault.receiveBridged(user, bridgeAmount);
        
        console.log("SUCCESS: Bridge receive successful");
        console.log("");
    }
    
    function test_09_WithdrawFromLendingPool() internal {
        uint256 withdrawAmount = 1000 * 10**18;
        
        console.log("--- Test 10: Withdraw from Lending Pool ---");
        console.log("Withdrawing", withdrawAmount / 10**18, "SPY");
        
        (uint256 beforePrincipal,,) = lendingPool.getUserBalance(user);
        
        lendingPool.withdraw(withdrawAmount);
        
        (uint256 afterPrincipal,,) = lendingPool.getUserBalance(user);
        console.log("Principal before:", beforePrincipal / 10**18);
        console.log("Principal after:", afterPrincipal / 10**18);
        
        require(afterPrincipal < beforePrincipal, "Withdraw failed");
        console.log("SUCCESS: Withdraw successful");
        console.log("");
    }
    
    function test_10_HarvestYield() internal {
        console.log("--- Test 12: Harvest Yield ---");
        
        (uint256 platformFee, uint256 userYield) = yieldRouter.harvest();
        console.log("Platform fee:", platformFee / 10**18);
        console.log("User yield:", userYield / 10**18);
        
        console.log("SUCCESS: Harvest successful");
        console.log("");
    }
    
    function test_99_FinalBalances() internal view {
        console.log("=== Final Balances ===");
        
        uint256 spyBalance = spyToken.balanceOf(user);
        console.log("SPY Token balance:", spyBalance / 10**18);
        
        (uint256 principal, uint256 interest, uint256 total) = lendingPool.getUserBalance(user);
        console.log("Lending Pool - Principal:", principal / 10**18);
        console.log("Lending Pool - Interest:", interest / 10**18);
        console.log("Lending Pool - Total:", total / 10**18);
        
        uint256 shares = shareToken.balanceOf(user);
        console.log("Share Tokens:", shares / 10**18);
        
        uint256 pendingYield = yieldRouter.getUserYield(user);
        console.log("Pending Yield:", pendingYield / 10**18);
        console.log("");
    }
}
