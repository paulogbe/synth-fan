# SynthFan Smart Contract - Usage Guide

## Contract Overview
This Clarity smart contract implements the core functionality of SynthFan platform:

1. **Fractional Creation Rights (FCR)** - Tokenized IP ownership
2. **Engagement Synthesis Tokens (EST)** - Interaction rights tokens
3. **Multi-Layer Licensing Protocol (MLLP)** - Flexible royalty structure
4. **Revenue Distribution** - Automated payouts to stakeholders
5. **Reputation System** - Trust building mechanism
6. **Collaborative Sessions** - Team creation tracking

## Key Features

### 1. Content Registration
```clarity
(contract-call? .synthfan register-content "My Amazing Song" u1000000)
```
- Registers new content with the platform
- Mints initial FCR tokens to creator
- Returns content-id for future reference

### 2. Licensing Layers
```clarity
(contract-call? .synthfan create-licensing-layer u1 "remix-rights" u500)
```
- Creates different IP licensing tiers
- Royalty percentage in basis points (500 = 5%)
- Multiple layers per content allowed

### 3. FCR Token Transfers
```clarity
(contract-call? .synthfan transfer-fcr u1 u100 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```
- Transfer fractional ownership to fans
- Enables secondary market trading
- Maintains provenance chain

### 4. EST Token Management
```clarity
;; Mint EST (owner only)
(contract-call? .synthfan mint-est 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u50)

;; Burn EST for interactions
(contract-call? .synthfan burn-est u10)
```

### 5. Revenue Distribution
```clarity
(contract-call? .synthfan distribute-revenue u1 u1000000)
```
- Distributes earnings to FCR holders
- Automatically deducts platform fee
- Creates auditable distribution record

### 6. Collaboration Sessions
```clarity
(contract-call? .synthfan start-collaboration-session u1)
```
- Initiates collaborative creation
- Tracks all participants
- Manages contribution attribution

## Read-Only Functions

### Query Content Info
```clarity
(contract-call? .synthfan get-content-info u1)
```

### Check FCR Balance
```clarity
(contract-call? .synthfan get-fcr-balance u1 tx-sender)
```

### Check EST Balance
```clarity
(contract-call? .synthfan get-est-balance tx-sender)
```

### Check Reputation Score
```clarity
(contract-call? .synthfan get-reputation-score tx-sender)
```

### Get Licensing Layer Details
```clarity
(contract-call? .synthfan get-licensing-layer u1 u1)
```

## Error Codes
- `u100` - Owner only operation
- `u101` - Content not found
- `u102` - Unauthorized access
- `u103` - Already exists
- `u104` - Invalid percentage
- `u105` - Insufficient balance
- `u106` - Invalid price

## Platform Fee
- Default: 2.5% (250 basis points)
- Adjustable by contract owner
- Maximum: 10%

## Security Features
1. **Access Control** - Only creators can manage their content
2. **Balance Validation** - Prevents overdraft transfers
3. **Percentage Limits** - Caps royalty percentages
4. **Immutable Records** - All distributions tracked on-chain
5. **Reputation System** - Incentivizes good behavior

## Integration Example

### Creator Workflow
1. Register content: `register-content`
2. Create licensing layers: `create-licensing-layer`
3. Sell FCR tokens to fans: Fans call `transfer-fcr` or use DEX
4. Distribute revenue: `distribute-revenue`

### Fan Workflow
1. Acquire EST tokens: Earn through engagement
2. Purchase FCR tokens: Secondary market
3. Participate in collaborations: `start-collaboration-session`
4. Build reputation: Active participation

### Platform Workflow
1. Mint EST tokens: Reward engagement
2. Monitor distributions: Track revenue flows
3. Adjust fees if needed: `update-platform-fee`

## Advanced Use Cases

### Derivative Work Creation
1. Fan purchases FCR tokens for remix rights layer
2. Creates derivative work
3. Registers as new content with reference to original
4. Original creator receives automatic royalties

### Collaborative Albums
1. Multiple creators start collaboration session
2. Each contributes and receives FCR tokens
3. Revenue automatically splits based on FCR ownership
4. Transparent attribution maintained

### Dynamic Pricing
1. High-reputation fans get EST token bonuses
2. Popular content increases FCR value
3. Licensing layers priced based on demand
4. Market-driven value discovery

## Deployment Notes
- Deploy on Stacks blockchain
- Compatible with Stacks 2.0+
- Requires STX for transaction fees
- Consider using testnet for initial testing

## Future Enhancements
- NFT integration for unique content pieces
- Cross-chain bridges for broader reach
- Governance token for platform decisions
- AI-powered predictive engagement analysis
- Automated market maker for FCR trading
