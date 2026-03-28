# SPEC.md — Unified

> One account. Every function. Private payments, public yield.
> 
> **Hackathon:** Rayls Developer Program @ EthCC Cannes
> **Challenge Track:** Autonomous Institution Agent + RWA Tokenization (hybrid)
> **Team:** Marc (Stripe + backend), Mads (smart contracts + DeFi integration)

---

## What We're Building

A unified banking account that eliminates the checking/savings/brokerage split. Users deposit once and get:

- Instant virtual Visa card (issued on deposit via Stripe Issuing)
- Private payments on the Rayls Privacy Node
- Passive yield from DeFi lending on Rayls Public L1
- Fractional share investing (tokenized on Public L1)

Users pay $0. Platform revenue = spread on DeFi lending yield.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                   USER LAYER                     │
│  Mobile/Web App  ←→  Stripe Virtual Visa Card    │
└──────────────┬──────────────────┬────────────────┘
               │                  │
               │ deposit/         │ card swipe
               │ balance          │ webhook
               ▼                  ▼
┌─────────────────────────────────────────────────┐
│              UNIFIED BACKEND (API)               │
│                                                  │
│  • User account management                       │
│  • Stripe Issuing integration (Marc)             │
│  • Balance oracle (reads Privacy Node state)     │
│  • Allocation engine (AI agent)                  │
│  • Bridge coordinator                            │
└──────┬──────────────────────────────┬────────────┘
       │                              │
       ▼                              ▼
┌──────────────────┐    ┌──────────────────────────┐
│  RAYLS PRIVACY   │    │    RAYLS PUBLIC L1        │
│     NODE         │    │                           │
│                  │    │  • UnifiedVault.sol        │
│  • UserLedger    │◄──►│  • YieldRouter.sol        │
│  • Private bal.  │    │  • LendingAdapter.sol     │
│  • Payment txs   │    │  • ShareToken.sol (ERC20) │
│  • KYC state     │    │  • Marketplace.sol        │
│                  │    │                           │
└──────────────────┘    └──────────────────────────┘
       Sovereign              Public / DeFi
```

---

## User Flows

### Flow 1: New User Deposit

```
User deposits funds (fiat on-ramp or crypto transfer)
  │
  ├─► [Privacy Node] Credit UserLedger with deposit amount
  │
  ├─► [Backend/Marc] Call Stripe Issuing → create virtual Visa card
  │     POST /v1/issuing/cards
  │     {
  │       type: "virtual",
  │       cardholder: <cardholder_id>,
  │       currency: "usd",
  │       spending_controls: {
  │         spending_limits: [{
  │           amount: <user_balance_cents>,
  │           interval: "all_time"
  │         }]
  │       }
  │     }
  │
  ├─► [Backend] Return card details to user (PAN, exp, CVC)
  │     User can add to Apple Pay / Google Pay immediately
  │
  └─► [Backend] AI allocation agent determines split:
        • Spending buffer → stays on Privacy Node (e.g. 20%)
        • Excess capital → bridge to Public L1 for DeFi lending (e.g. 80%)
          └─► [Mads] UnifiedVault.sol receives bridged funds
              └─► YieldRouter.sol deposits into lending protocol
```

### Flow 2: Card Payment (Critical Path)

```
User swipes Visa card at merchant
  │
  ├─► Stripe sends issuing_authorization.request webhook
  │
  ├─► [Backend/Marc] Webhook handler:
  │     1. Read authorization amount from webhook payload
  │     2. Query Privacy Node for user's current balance
  │     3. IF balance >= amount:
  │          → Approve authorization (respond 200 with approved: true)
  │          → Debit UserLedger on Privacy Node
  │          → Update Stripe spending_limits to new balance
  │        ELSE IF balance < amount BUT (balance + public_deposits) >= amount:
  │          → Initiate emergency bridge-back from Public L1
  │          → Approve authorization
  │          → Debit across both layers
  │        ELSE:
  │          → Decline authorization (respond 200 with approved: false)
  │
  └─► [Privacy Node] Transaction recorded privately
      (merchant sees normal Visa payment, knows nothing about Rayls)
```

### Flow 3: Yield Accrual

```
Continuously (AI agent / cron):
  │
  ├─► [Mads] YieldRouter.sol harvests lending yield
  │     • Calls claim/harvest on lending protocol
  │     • Calculates platform spread (e.g. protocol earns 6.5%, user gets 4.2%)
  │     • Platform fee accumulates in ProtocolTreasury
  │
  ├─► [Backend] Periodically bridge user's yield portion back to Privacy Node
  │     • Update UserLedger balance
  │     • Update Stripe spending_limits
  │
  └─► [Frontend] User sees yield in app: "+$4.12 today"
```

### Flow 4: Fractional Investing

```
User selects asset (e.g. "Buy $50 of AAPL")
  │
  ├─► [Privacy Node] Debit $50 from UserLedger
  │
  ├─► [Bridge] Move $50 to Public L1
  │
  ├─► [Mads] ShareToken.sol mints fractional position token
  │     • ERC20 representing fractional share
  │     • AI attestation of underlying asset posted on-chain
  │
  └─► [Privacy Node] Record position in user's private portfolio
      (public chain sees the token, but not who owns it)
```

---

## Team Responsibilities

### Marc — Stripe Integration + Backend API

**Owns:**
- Stripe Issuing integration (card creation, authorization webhooks, spending limit updates)
- Backend API server (Node.js or Python)
- User account management
- Balance oracle (reads Privacy Node state for Stripe authorization decisions)
- Bridge coordination logic (when to move funds between chains)

**Key Stripe endpoints:**
- `POST /v1/issuing/cardholders` — create cardholder on user signup
- `POST /v1/issuing/cards` — issue virtual card on first deposit
- `POST /v1/issuing/authorizations/{id}/approve` — approve card swipe
- `POST /v1/issuing/authorizations/{id}/decline` — decline card swipe
- `PATCH /v1/issuing/cards/{id}` — update spending limits after balance changes
- Webhook: `issuing_authorization.request` — real-time authorization decision (must respond within 2 seconds)

**Critical constraint:** The Stripe authorization webhook gives you ~2 seconds to respond. The Privacy Node balance check MUST be fast. Cache aggressively. Consider keeping a hot balance cache in Redis that syncs with Privacy Node state.

**Stripe Issuing sandbox setup:**
1. Enable Issuing in Stripe Dashboard (test mode)
2. Create a test cardholder
3. Issue a test virtual card
4. Use Stripe CLI to forward webhooks locally: `stripe listen --forward-to localhost:3000/webhooks/stripe`
5. Simulate authorizations: `stripe issuing authorizations create --amount=1000 --card=<card_id>`

### Mads — Smart Contracts + DeFi Integration

**Owns:**
- All Solidity contracts deployed to Rayls Privacy Node and Public L1
- Bridge interaction logic (Privacy Node ↔ Public L1)
- DeFi lending integration on Public L1
- Tokenized share contracts
- AI attestation contracts

**Contracts to build:**

#### Privacy Node Contracts

**UserLedger.sol**
```
- mapping(address => uint256) private balances
- mapping(address => Position[]) private positions
- deposit(address user, uint256 amount) → credit balance
- debit(address user, uint256 amount) → reduce balance (called on card swipe)
- getBalance(address user) → uint256 (called by Marc's balance oracle)
- recordPayment(address user, uint256 amount, bytes32 merchantHash) → emit private event
```

**PrivacyGovernor.sol**
```
- Manages disclosure rules: what gets revealed to Public L1
- approveDisclosure(bytes32 assetId, DisclosureLevel level)
- DisclosureLevel: NONE | EXISTENCE_ONLY | PARTIAL | FULL
- AI agent calls this to approve bridging of assets
```

#### Public L1 Contracts

**UnifiedVault.sol**
```
- Receives bridged funds from Privacy Node
- Routes to YieldRouter based on allocation strategy
- receiveBridged(address user, uint256 amount) → called by bridge
- withdrawToPrivacy(address user, uint256 amount) → bridge back
- emergencyWithdraw(address user, uint256 amount) → fast path for card auth
```

**YieldRouter.sol**
```
- Abstract routing layer for DeFi lending
- deposit(uint256 amount, address protocol) → supply to lending pool
- withdraw(uint256 amount, address protocol) → remove from lending pool
- harvest() → claim yield, split between user and protocol treasury
- getYieldRate(address protocol) → current APY
- Adapters:
    - AaveLikeAdapter (if available on Rayls)
    - GenericLendingAdapter (fallback: simple interest-bearing vault)
```

**LendingPool.sol (if no existing DeFi on Rayls Public L1)**
```
- Simple lending pool for demo purposes
- We may need to deploy our own since Rayls Public L1 is new
- supply(uint256 amount) → deposit and start earning
- borrow(uint256 amount, uint256 collateral) → borrow against collateral
- Variable interest rate model: utilization-based
- This IS the platform revenue source
```

**ShareToken.sol**
```
- ERC20 representing fractional shares of real-world assets
- mint(address to, uint256 amount, bytes32 attestationHash)
- burn(address from, uint256 amount)
- attestation: AI agent posts signed proof of underlying asset
- Tradeable on Public L1 marketplace
```

**ProtocolTreasury.sol**
```
- Accumulates platform yield spread
- Simple collection contract
- collectFee(uint256 amount)
- getAccumulated() → total platform revenue
- Visible on Public L1 for transparency
```

**AIAttestation.sol**
```
- On-chain record of AI agent decisions
- postAttestation(bytes32 assetId, bytes signature, string metadata)
- verifyAttestation(bytes32 assetId) → bool
- Used for: compliance review, asset existence proofs, yield audits
```

---

## Judging Criteria Alignment

| Criteria | How We Hit It |
|---|---|
| **Sovereignty** | All user balances, payment history, and portfolio positions live exclusively on the Privacy Node. None of this is possible on a public chain — users would have their entire financial life exposed. |
| **Disclosure Design** | Only aggregated deposit amounts cross to Public L1 for lending. Individual transactions stay private. AI attestation proves asset existence without revealing details. Fractional shares are public tokens but ownership mapping is private. |
| **AI Integration** | AI allocation agent decides fund split (spending buffer vs. yield). AI compliance agent reviews disclosures before bridging. AI attestation oracle posts signed proofs on Public L1. All produce on-chain artifacts. |
| **Public Market Viability** | LendingPool on Public L1 is a real market anyone can interact with. ShareTokens are tradeable ERC20s. ProtocolTreasury shows transparent revenue. |
| **Working Prototype** | Live card issuance demo (Stripe sandbox). Real transactions on Privacy Node visible in explorer. Bridged funds visible on Public L1. Yield accruing in real-time. |

---

## Demo Script (Sunday presentation)

1. **"Here's a bank account"** — open the app, show unified balance
2. **"Watch me get a card"** — deposit funds, virtual Visa appears instantly
3. **"I'll buy a coffee"** — simulate card swipe, show Privacy Node debit in real-time
4. **"Where's my money working?"** — show 80% of idle funds earning yield on Public L1
5. **"My balance just grew"** — show yield accrual hitting the account
6. **"Nobody sees my transactions"** — show Privacy Node explorer (private) vs Public L1 (only vault deposits visible)
7. **"The platform makes money"** — show ProtocolTreasury accumulating spread
8. **"One account. No walls. No fees."** — back to the balance screen

---

## Tech Stack

| Component | Tech |
|---|---|
| Frontend | HTML/CSS/JS (existing index.html demo) |
| Backend API | Node.js + Express (or Python FastAPI) |
| Card Issuing | Stripe Issuing API (test mode) |
| Privacy Node | Rayls Privacy Node (EVM, provided by hackathon) |
| Public Chain | Rayls Public L1 (EVM, reth-based) |
| Smart Contracts | Solidity, Hardhat/Foundry |
| Bridge | Rayls built-in Privacy Node ↔ Public L1 bridge |
| AI Agent | Claude API or local LLM for allocation/attestation |
| Cache | Redis (for fast balance lookups on card auth) |

---

## Day-by-Day Plan

### Day 1 (Friday)
- **Both:** Onboarding call with Rayls team, get Privacy Node access, test bridge
- **Marc:** Stripe Issuing sandbox setup, webhook handler skeleton, basic API server
- **Mads:** Deploy UserLedger.sol to Privacy Node, deploy UnifiedVault.sol + LendingPool.sol to Public L1

### Day 2 (Saturday)
- **Marc:** Full card authorization flow (webhook → balance check → approve/decline → debit), spending limit sync, bridge coordination endpoints
- **Mads:** YieldRouter.sol + adapters, bridge integration (deposit to Privacy → bridge to Public → supply to lending), harvest + fee split logic, ShareToken.sol
- **Both (evening):** Integration testing — deposit → card issue → swipe → debit → yield cycle

### Day 3 (Sunday)
- **Morning:** AI attestation integration, PrivacyGovernor disclosure flow, polish
- **Afternoon:** Demo rehearsal, bug fixes, make sure explorer shows transactions
- **Evening:** Present → Happy Hour

---

## Open Questions (Resolve at Onboarding Call)

1. What RPC endpoint / chain ID does the Privacy Node expose?
2. What's the bridge contract interface? Is it a lock-and-mint or message-passing model?
3. Is there an existing lending protocol on Rayls Public L1, or do we deploy our own?
4. What token standard do Privacy Node assets use? Standard ERC20 or custom?
5. Bridge latency — how fast can we move funds back for emergency card authorizations?
6. Is there a block explorer for both chains we can point to during the demo?
7. Gas / transaction fees on Privacy Node — free? subsidized?
