# RaylsFi - Unified Banking on Rayls

> One account. Every function. Private payments, public yield.

A unified banking account that eliminates the checking/savings/brokerage split. Users deposit once and get instant virtual Visa cards, private payments on the Rayls Privacy Node, passive yield from DeFi lending on Rayls Public L1, and fractional share investing.

**Hackathon:** Rayls Developer Program @ EthCC Cannes  
**Challenge Track:** Autonomous Institution Agent + RWA Tokenization (hybrid)

## Architecture

### Privacy Node (Account Management & Payments)
- **UserLedger.sol** - Private balance tracking and payment recording
- **PrivacyGovernor.sol** - Disclosure control and governance

### Public Chain (Lending Protocol & Yield)
- **MockSPY.sol** - Mock S&P 500 ETF token for lending
- **LendingPool.sol** - Variable interest rate lending protocol
- **UnifiedVault.sol** - Bridge receiver and fund coordinator
- **YieldRouter.sol** - DeFi yield routing with platform fees
- **ProtocolTreasury.sol** - Platform revenue collection
- **ShareToken.sol** - Fractional RWA tokenization
- **AIAttestation.sol** - AI agent attestation registry

## Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js 18+ (for backend integration)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd raylsFi

# Install dependencies
forge install

# Copy environment template
cp .env.example .env
```

### Configuration

Edit `.env` and add your deployer private key:

```bash
# Generate a new wallet
cast wallet new

# Add the private key to .env
DEPLOYER_PRIVATE_KEY=<your-private-key>
```

The other environment variables are pre-configured for the Rayls hackathon:

```
PRIVACY_NODE_RPC_URL=https://privacy-node-2.rayls.com
PRIVACY_NODE_CHAIN_ID=800002
PUBLIC_CHAIN_RPC_URL=https://testnet-rpc.rayls.com/
PUBLIC_CHAIN_ID=7295799
```

### Deployment

#### 1. Deploy to Public Chain (Rayls Testnet)

Deploy the SPY lending protocol:

```bash
./scripts/deploy-public.sh
```

This deploys:
- MockSPY token (for testing)
- LendingPool (variable interest rate lending)
- UnifiedVault (bridge receiver)
- YieldRouter (yield distribution)
- ProtocolTreasury (platform fees)
- ShareToken (fractional shares)
- AIAttestation (AI agent registry)

**Save the deployed contract addresses!** You'll need them for integration.

#### 2. Deploy to Privacy Node

Deploy account management contracts:

```bash
./scripts/deploy-privacy.sh
```

This deploys:
- UserLedger (private balance tracking)
- PrivacyGovernor (disclosure control)

### Testing the Lending Protocol

After deployment, you can test the lending protocol:

```bash
# Load environment
source .env

# Get your deployer address
DEPLOYER=$(cast wallet address --private-key $DEPLOYER_PRIVATE_KEY)

# Approve LendingPool to spend SPY tokens
cast send <SPY_TOKEN_ADDRESS> "approve(address,uint256)" <LENDING_POOL_ADDRESS> 10000000000000000000000 \
  --rpc-url $PUBLIC_CHAIN_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY

# Supply 1000 SPY to the lending pool
cast send <LENDING_POOL_ADDRESS> "supply(uint256)" 1000000000000000000000 \
  --rpc-url $PUBLIC_CHAIN_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY

# Check your balance
cast call <LENDING_POOL_ADDRESS> "getUserBalance(address)(uint256,uint256,uint256)" $DEPLOYER \
  --rpc-url $PUBLIC_CHAIN_RPC_URL

# Check current APY
cast call <LENDING_POOL_ADDRESS> "getCurrentAPY()(uint256)" \
  --rpc-url $PUBLIC_CHAIN_RPC_URL
```

## Contract Interactions

### Privacy Node - UserLedger

```solidity
// Deposit funds (owner only)
userLedger.deposit(userAddress, amount);

// Debit for payment (owner only)
userLedger.debit(userAddress, amount);

// Get balance
uint256 balance = userLedger.getBalance(userAddress);

// Record payment
userLedger.recordPayment(userAddress, amount, merchantHash);

// Initiate bridge to public chain
userLedger.initiateBridge(userAddress, amount);
```

### Public Chain - LendingPool

```solidity
// Supply assets to earn yield
lendingPool.supply(amount);

// Withdraw assets + interest
lendingPool.withdraw(amount);

// Borrow with collateral (150% collateralization)
lendingPool.borrow(borrowAmount, collateralAmount);

// Repay borrowed amount
lendingPool.repay(amount);

// Get current APY
uint256 apy = lendingPool.getCurrentAPY();
```

### Public Chain - YieldRouter

```solidity
// Deposit to yield strategy (vault/owner only)
yieldRouter.deposit(amount, userAddress);

// Harvest yield and distribute fees
(uint256 platformFee, uint256 userYield) = yieldRouter.harvest();

// Get user's pending yield
uint256 yield = yieldRouter.getUserYield(userAddress);

// Get current yield rate
uint256 rate = yieldRouter.getYieldRate();
```

## User Flows

### Flow 1: New User Deposit
1. User deposits funds → credited to UserLedger on Privacy Node
2. Backend issues virtual Visa card via Stripe
3. AI agent allocates funds: 20% spending buffer, 80% to DeFi
4. Funds bridge to Public L1 → UnifiedVault → YieldRouter → LendingPool

### Flow 2: Card Payment
1. User swipes Visa card
2. Stripe webhook → Backend checks Privacy Node balance
3. If sufficient: approve & debit UserLedger
4. If insufficient: emergency bridge from Public L1

### Flow 3: Yield Accrual
1. YieldRouter harvests lending yield
2. Platform fee (23%) → ProtocolTreasury
3. User yield (77%) → distributed back to Privacy Node
4. User sees yield in app

### Flow 4: Fractional Investing
1. User selects asset (e.g., "Buy $50 of AAPL")
2. Debit from Privacy Node
3. Bridge to Public L1
4. ShareToken mints fractional position
5. AI attestation posted on-chain

## Explorers

- **Privacy Node:** https://blockscout-privacy-node-2.rayls.com
- **Public Chain:** https://testnet-explorer.rayls.com/

## Revenue Model

Platform earns spread on DeFi lending yield:
- Lending pool earns: ~6.5% APY
- Users receive: ~4.2% APY
- Platform keeps: ~2.3% (35% of yield)

## Next Steps

1. **Backend Integration** - Connect Stripe Issuing API
2. **Bridge Integration** - Implement Privacy Node ↔ Public L1 bridge
3. **AI Agent** - Build allocation and attestation agents
4. **Frontend** - Build user dashboard
5. **Testing** - End-to-end flow testing

## Resources

- [Rayls Documentation](https://docs.rayls.com)
- [Hackathon Starter](https://github.com/raylsnetwork/rayls-hackathon-starter)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT
