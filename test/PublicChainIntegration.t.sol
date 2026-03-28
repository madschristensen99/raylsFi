// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/public-chain/MockSPY.sol";
import "../contracts/public-chain/LendingPool.sol";
import "../contracts/public-chain/UnifiedVault.sol";
import "../contracts/public-chain/YieldRouter.sol";
import "../contracts/public-chain/ProtocolTreasury.sol";
import "../contracts/public-chain/ShareToken.sol";
import "../contracts/public-chain/AIAttestation.sol";

contract PublicChainIntegrationTest is Test {
    // Deployed contract addresses on testnet
    MockSPY public spyToken = MockSPY(0xec25ce0d80c44cb8370dc71f6d1d4585244212d7);
    LendingPool public lendingPool = LendingPool(0x52892eae906f502c4e402301cdd13f3123ead729);
    UnifiedVault public vault = UnifiedVault(0xf418c8cbdc3422b26b28408dc31aa8b4eece54ce);
    ProtocolTreasury public treasury = ProtocolTreasury(0x43d1ecf020297ad344ce740c8e69ce0a2fecb825);
    YieldRouter public yieldRouter = YieldRouter(0xd7bd1e8531f79a9fb59b3245a37d8c4602c5b96b);
    ShareToken public shareToken = ShareToken(0x3960a2a73b6abbb69f352a691ef5a9339f763c8c);
    AIAttestation public aiAttestation = AIAttestation(0x5c8cec43ce559b90ffb4c3f15fabede220cc24c0);
    
    address public user;
    uint256 public userPrivateKey;
    
    function setUp() public {
        userPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        user = vm.addr(userPrivateKey);
        
        vm.startBroadcast(userPrivateKey);
        
        console.log("=== Public Chain Integration Test Setup ===");
        console.log("User address:", user);
        console.log("SPY Token:", address(spyToken));
        console.log("Lending Pool:", address(lendingPool));
    }
    
    function test_01_MintSPYTokens() public {
        uint256 mintAmount = 50000 * 10**18;
        
        console.log("\n--- Test 1: Mint SPY Tokens ---");
        console.log("Minting", mintAmount / 10**18, "SPY tokens");
        
        spyToken.mint(user, mintAmount);
        
        uint256 balance = spyToken.balanceOf(user);
        console.log("User SPY balance:", balance / 10**18);
        
        require(balance >= mintAmount, "Mint failed");
        console.log("Mint successful");
    }
    
    function test_02_ApproveLendingPool() public {
        uint256 approvalAmount = 100000 * 10**18;
        
        console.log("\n--- Test 2: Approve Lending Pool ---");
        console.log("Approving", approvalAmount / 10**18, "SPY tokens");
        
        spyToken.approve(address(lendingPool), approvalAmount);
        
        uint256 allowance = spyToken.allowance(user, address(lendingPool));
        console.log("Allowance:", allowance / 10**18);
        
        require(allowance >= approvalAmount, "Approval failed");
        console.log("Approval successful");
    }
    
    function test_03_SupplyToLendingPool() public {
        uint256 supplyAmount = 5000 * 10**18;
        
        console.log("\n--- Test 3: Supply to Lending Pool ---");
        console.log("Supplying", supplyAmount / 10**18, "SPY tokens");
        
        lendingPool.supply(supplyAmount);
        
        (uint256 principal, uint256 interest, uint256 total) = lendingPool.getUserBalance(user);
        console.log("Principal:", principal / 10**18);
        console.log("Interest:", interest / 10**18);
        console.log("Total:", total / 10**18);
        
        require(principal >= supplyAmount, "Supply failed");
        console.log("Supply successful");
    }
    
    function test_04_CheckLendingPoolAPY() public view {
        console.log("\n--- Test 4: Check Lending Pool APY ---");
        
        uint256 apy = lendingPool.getCurrentAPY();
        console.log("Current APY (basis points):", apy);
        console.log("Current APY (%):", apy / 100);
        
        console.log("APY check successful");
    }
    
    function test_05_BorrowFromLendingPool() public {
        uint256 borrowAmount = 1000 * 10**18;
        uint256 collateralAmount = 1500 * 10**18;
        
        console.log("\n--- Test 5: Borrow from Lending Pool ---");
        console.log("Borrowing", borrowAmount / 10**18, "SPY");
        console.log("Collateral", collateralAmount / 10**18, "SPY");
        
        lendingPool.borrow(borrowAmount, collateralAmount);
        
        (uint256 borrowed, uint256 collateral) = lendingPool.getUserBorrow(user);
        console.log("Borrowed amount:", borrowed / 10**18);
        console.log("Collateral amount:", collateral / 10**18);
        
        require(borrowed >= borrowAmount, "Borrow failed");
        console.log("Borrow successful");
    }
    
    function test_06_DepositToYieldRouter() public {
        uint256 depositAmount = 2000 * 10**18;
        
        console.log("\n--- Test 6: Deposit to Yield Router ---");
        console.log("Depositing", depositAmount / 10**18, "SPY to YieldRouter");
        
        spyToken.approve(address(yieldRouter), depositAmount);
        yieldRouter.deposit(depositAmount, user);
        
        uint256 userYield = yieldRouter.getUserYield(user);
        console.log("User pending yield:", userYield / 10**18);
        
        console.log("Deposit to YieldRouter successful");
    }
    
    function test_07_MintShareTokens() public {
        uint256 shares = 100 * 10**18;
        
        console.log("\n--- Test 7: Mint Share Tokens ---");
        console.log("Minting", shares / 10**18, "rfSPY shares");
        
        shareToken.mint(user, shares);
        
        uint256 balance = shareToken.balanceOf(user);
        console.log("Share token balance:", balance / 10**18);
        
        require(balance >= shares, "Share mint failed");
        console.log("Share token mint successful");
    }
    
    function test_08_RecordAIAttestation() public {
        bytes32 assetId = keccak256("AAPL-FRACTIONAL-001");
        string memory attestation = "AI verified: Apple Inc. fractional share ownership";
        
        console.log("\n--- Test 8: Record AI Attestation ---");
        console.log("Asset ID:", vm.toString(assetId));
        
        aiAttestation.recordAttestation(assetId, attestation);
        
        (string memory storedAttestation, uint256 timestamp, address attester) = aiAttestation.getAttestation(assetId);
        console.log("Attestation:", storedAttestation);
        console.log("Timestamp:", timestamp);
        console.log("Attester:", attester);
        
        require(keccak256(bytes(storedAttestation)) == keccak256(bytes(attestation)), "Attestation failed");
        console.log("AI attestation successful");
    }
    
    function test_09_BridgeReceive() public {
        uint256 bridgeAmount = 500 * 10**18;
        
        console.log("\n--- Test 9: Bridge Receive ---");
        console.log("Simulating bridge receive of", bridgeAmount / 10**18, "SPY");
        
        spyToken.approve(address(vault), bridgeAmount);
        vault.bridgeReceive(user, bridgeAmount);
        
        console.log("Bridge receive successful");
    }
    
    function test_10_WithdrawFromLendingPool() public {
        uint256 withdrawAmount = 1000 * 10**18;
        
        console.log("\n--- Test 10: Withdraw from Lending Pool ---");
        console.log("Withdrawing", withdrawAmount / 10**18, "SPY");
        
        (uint256 beforePrincipal,,) = lendingPool.getUserBalance(user);
        
        lendingPool.withdraw(withdrawAmount);
        
        (uint256 afterPrincipal,,) = lendingPool.getUserBalance(user);
        console.log("Principal before:", beforePrincipal / 10**18);
        console.log("Principal after:", afterPrincipal / 10**18);
        
        require(afterPrincipal < beforePrincipal, "Withdraw failed");
        console.log("Withdraw successful");
    }
    
    function test_11_RepayBorrow() public {
        uint256 repayAmount = 500 * 10**18;
        
        console.log("\n--- Test 11: Repay Borrow ---");
        console.log("Repaying", repayAmount / 10**18, "SPY");
        
        (uint256 beforeBorrowed,) = lendingPool.getUserBorrow(user);
        
        lendingPool.repay(repayAmount);
        
        (uint256 afterBorrowed,) = lendingPool.getUserBorrow(user);
        console.log("Borrowed before:", beforeBorrowed / 10**18);
        console.log("Borrowed after:", afterBorrowed / 10**18);
        
        require(afterBorrowed < beforeBorrowed, "Repay failed");
        console.log("Repay successful");
    }
    
    function test_12_HarvestYield() public {
        console.log("\n--- Test 12: Harvest Yield ---");
        
        (uint256 platformFee, uint256 userYield) = yieldRouter.harvest();
        console.log("Platform fee:", platformFee / 10**18);
        console.log("User yield:", userYield / 10**18);
        
        console.log("Harvest successful");
    }
    
    function test_99_FinalBalances() public view {
        console.log("\n=== Final Balances ===");
        
        uint256 spyBalance = spyToken.balanceOf(user);
        console.log("SPY Token balance:", spyBalance / 10**18);
        
        (uint256 principal, uint256 interest, uint256 total) = lendingPool.getUserBalance(user);
        console.log("Lending Pool - Principal:", principal / 10**18);
        console.log("Lending Pool - Interest:", interest / 10**18);
        console.log("Lending Pool - Total:", total / 10**18);
        
        (uint256 borrowed, uint256 collateral) = lendingPool.getUserBorrow(user);
        console.log("Lending Pool - Borrowed:", borrowed / 10**18);
        console.log("Lending Pool - Collateral:", collateral / 10**18);
        
        uint256 shares = shareToken.balanceOf(user);
        console.log("Share Tokens:", shares / 10**18);
        
        uint256 pendingYield = yieldRouter.getUserYield(user);
        console.log("Pending Yield:", pendingYield / 10**18);
    }
}
