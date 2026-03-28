# RaylsFi Deployment Guide

This guide walks you through deploying the RaylsFi lending protocol and account management system to the Rayls networks.

## Prerequisites

1. **Generate a wallet** (if you don't have one):
```bash
cast wallet new
```

Save the private key and address securely.

2. **Get testnet tokens** from the faucet or contact Nuno (Mentor) for more tokens:
   - Public Chain: https://testnet-explorer.rayls.com/
   - Send your address to get USDr tokens

3. **Configure environment**:
```bash
cp .env.example .env
```

Edit `.env` and add your private key:
```
DEPLOYER_PRIVATE_KEY=<your-private-key-here>
```

## Step 1: Deploy to Public Chain (Rayls Testnet)

This deploys the SPY lending protocol and all DeFi infrastructure.

```bash
source .env
./scripts/deploy-public.sh
```

**Contracts deployed:**
- ✅ MockSPY - Mock S&P 500 token for testing
- ✅ LendingPool - Variable interest rate lending protocol
- ✅ UnifiedVault - Bridge receiver and fund coordinator
- ✅ YieldRouter - Yield distribution with platform fees (23% spread)
- ✅ ProtocolTreasury - Platform revenue collection
- ✅ ShareToken - Fractional RWA shares
- ✅ AIAttestation - AI agent attestation registry

**Save the contract addresses!** You'll need them for the next steps.

Example output:
```
MockSPY: 0x1234...
LendingPool: 0x5678...
UnifiedVault: 0x9abc...
YieldRouter: 0xdef0...
ProtocolTreasury: 0x1111...
ShareToken: 0x2222...
AIAttestation: 0x3333...
```

### Verify Deployment

Check on the explorer:
https://testnet-explorer.rayls.com/

## Step 2: Deploy to Privacy Node

This deploys the private account management contracts.

```bash
source .env
./scripts/deploy-privacy.sh
```

**Contracts deployed:**
- ✅ UserLedger - Private balance tracking and payment recording
- ✅ PrivacyGovernor - Disclosure control and governance

**Save these addresses too!**

### Verify Deployment

Check on the Privacy Node explorer:
https://blockscout-privacy-node-2.rayls.com

## Step 3: Test the Lending Protocol

Now let's test the SPY lending pool with some transactions.

### 3.1 Get Your Deployer Address

```bash
source .env
DEPLOYER=$(cast wallet address --private-key $DEPLOYER_PRIVATE_KEY)
echo "Deployer address: $DEPLOYER"
```

### 3.2 Set Contract Addresses

Replace with your actual deployed addresses:

```bash
SPY_TOKEN=0x... # Your MockSPY address
LENDING_POOL=0x... # Your LendingPool address
UNIFIED_VAULT=0x... # Your UnifiedVault address
YIELD_ROUTER=0x... # Your YieldRouter address
```

### 3.3 Check Initial Balance

```bash
cast call $SPY_TOKEN "balanceOf(address)(uint256)" $DEPLOYER \
  --rpc-url $PUBLIC_CHAIN_RPC_URL
```

### 3.4 Approve LendingPool

```bash
cast send $SPY_TOKEN "approve(address,uint256)" $LENDING_POOL 10000000000000000000000 \
  --rpc-url $PUBLIC_CHAIN_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY
```

### 3.5 Supply to Lending Pool

Supply 1000 SPY tokens:

```bash
cast send $LENDING_POOL "supply(uint256)" 1000000000000000000000 \
  --rpc-url $PUBLIC_CHAIN_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY
```

### 3.6 Check Your Lending Balance

```bash
cast call $LENDING_POOL "getUserBalance(address)(uint256,uint256,uint256)" $DEPLOYER \
  --rpc-url $PUBLIC_CHAIN_RPC_URL
```

Returns: (principal, interest, total)

### 3.7 Check Current APY

```bash
cast call $LENDING_POOL "getCurrentAPY()(uint256)" \
  --rpc-url $PUBLIC_CHAIN_RPC_URL
```

APY is returned in basis points (e.g., 200 = 2%)

### 3.8 Wait and Check Interest

Wait a few minutes, then check your balance again to see interest accrual:

```bash
cast call $LENDING_POOL "getUserBalance(address)(uint256,uint256,uint256)" $DEPLOYER \
  --rpc-url $PUBLIC_CHAIN_RPC_URL
```

## Step 4: Test Privacy Node Contracts

### 4.1 Set Privacy Node Addresses

```bash
USER_LEDGER=0x... # Your UserLedger address
PRIVACY_GOVERNOR=0x... # Your PrivacyGovernor address
```

### 4.2 Deposit to User Account

```bash
# Deposit 1000 units to a user account
cast send $USER_LEDGER "deposit(address,uint256)" $DEPLOYER 1000000000000000000000 \
  --rpc-url $PRIVACY_NODE_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY
```

### 4.3 Check User Balance

```bash
cast call $USER_LEDGER "getBalance(address)(uint256)" $DEPLOYER \
  --rpc-url $PRIVACY_NODE_RPC_URL
```

### 4.4 Record a Payment

```bash
# Record a payment (e.g., $50 coffee purchase)
MERCHANT_HASH=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

cast send $USER_LEDGER "recordPayment(address,uint256,bytes32)" \
  $DEPLOYER 50000000000000000000 $MERCHANT_HASH \
  --rpc-url $PRIVACY_NODE_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY
```

### 4.5 Check Payment Count

```bash
cast call $USER_LEDGER "getPaymentCount(address)(uint256)" $DEPLOYER \
  --rpc-url $PRIVACY_NODE_RPC_URL
```

## Step 5: Update Environment File

Add all deployed addresses to your `.env` file for future reference:

```bash
# Public Chain Contracts
SPY_TOKEN_ADDRESS=0x...
LENDING_POOL_ADDRESS=0x...
UNIFIED_VAULT_ADDRESS=0x...
YIELD_ROUTER_ADDRESS=0x...
PROTOCOL_TREASURY_ADDRESS=0x...
SHARE_TOKEN_ADDRESS=0x...
AI_ATTESTATION_ADDRESS=0x...

# Privacy Node Contracts
USER_LEDGER_ADDRESS=0x...
PRIVACY_GOVERNOR_ADDRESS=0x...
```

## Next Steps

### Backend Integration

1. **Stripe Integration** - Set up Stripe Issuing for virtual cards
2. **Balance Oracle** - Connect backend to read Privacy Node balances
3. **Bridge Coordinator** - Implement fund movement between chains
4. **Webhook Handler** - Process card authorization requests

### AI Agent Setup

1. **Allocation Agent** - Decide fund split (spending vs. yield)
2. **Attestation Agent** - Generate asset proofs
3. **Compliance Agent** - Review disclosure requests

### Frontend Development

1. Build user dashboard showing unified balance
2. Display yield accrual in real-time
3. Show private transaction history
4. Card management interface

## Troubleshooting

### "Insufficient funds" error
- Make sure you have enough USDr tokens for gas
- Contact Nuno for more testnet tokens

### "Contract not found" error
- Verify the contract address is correct
- Check the explorer to confirm deployment

### "Execution reverted" error
- Check you have sufficient token balance
- Verify approvals are set correctly
- Ensure you're using the correct RPC URL

## Useful Commands

### Check gas balance
```bash
cast balance $DEPLOYER --rpc-url $PUBLIC_CHAIN_RPC_URL
```

### Check transaction receipt
```bash
cast receipt <tx-hash> --rpc-url $PUBLIC_CHAIN_RPC_URL
```

### Call any contract function
```bash
cast call <contract-address> "functionName(args)(returnType)" <args> \
  --rpc-url <rpc-url>
```

### Send transaction
```bash
cast send <contract-address> "functionName(args)" <args> \
  --rpc-url <rpc-url> \
  --private-key $DEPLOYER_PRIVATE_KEY
```

## Support

- **Block Explorers:**
  - Public: https://testnet-explorer.rayls.com/
  - Privacy: https://blockscout-privacy-node-2.rayls.com
  
- **Documentation:** https://docs.rayls.com

- **Mentor:** Nuno (for testnet tokens and technical support)
