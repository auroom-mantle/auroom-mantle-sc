# Post-Deployment Setup Scripts

Scripts to configure the protocol after deploying all contracts.

## Usage

Run these scripts in order after completing all deployments:

### 1. Register Contracts in KYC

Registers BorrowingProtocolV2 and SwapRouter in IdentityRegistry so they can receive XAUT.

```bash
forge script script/mantle/post-deployment/Setup01_RegisterKYC.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast
```

### 2. Mint IDRX to Treasury

Mints IDRX tokens to the treasury wallet for the lending pool.

```bash
forge script script/mantle/post-deployment/Setup02_MintTreasury.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast
```

**Optional environment variables:**
- `TREASURY` - Override treasury address (defaults to deployer)
- `MINT_AMOUNT` - Override mint amount in wei (defaults to 100T IDRX)

### 3. Approve Protocol

Approves BorrowingProtocolV2 to spend IDRX from treasury.

```bash
forge script script/mantle/post-deployment/Setup03_ApproveProtocol.s.sol \
  --rpc-url $MANTLE_SEPOLIA_RPC \
  --broadcast
```

## Required Environment Variables

```bash
PRIVATE_KEY=<deployer_private_key>
MANTLE_SEPOLIA_RPC=https://rpc.sepolia.mantle.xyz
MOCK_IDRX=<deployed_address>
IDENTITY_REGISTRY=<deployed_address>
BORROWING_PROTOCOL_V2=<deployed_address>
SWAP_ROUTER=<deployed_address>  # Optional for Setup01
```

## Verification

After running all setup scripts, verify the configuration:

```bash
# Check if BorrowingProtocolV2 is verified in KYC
cast call $IDENTITY_REGISTRY 'isVerified(address)' $BORROWING_PROTOCOL_V2 \
  --rpc-url $MANTLE_SEPOLIA_RPC

# Check treasury IDRX balance
cast call $MOCK_IDRX 'balanceOf(address)' $TREASURY \
  --rpc-url $MANTLE_SEPOLIA_RPC

# Check protocol IDRX allowance
cast call $MOCK_IDRX 'allowance(address,address)' $TREASURY $BORROWING_PROTOCOL_V2 \
  --rpc-url $MANTLE_SEPOLIA_RPC
```

## Post-Setup Testing

Once setup is complete, test the full borrow flow:

1. **Register a test user in KYC:**
   ```bash
   cast send $IDENTITY_REGISTRY "registerIdentity(address)" $TEST_ADDRESS \
     --rpc-url $MANTLE_SEPOLIA_RPC \
     --private-key $PRIVATE_KEY
   ```

2. **Mint XAUT to test user:**
   ```bash
   cast send $XAUT "mint(address,uint256)" $TEST_ADDRESS 10000000 \
     --rpc-url $MANTLE_SEPOLIA_RPC \
     --private-key $PRIVATE_KEY
   ```

3. **User approves and borrows:**
   ```bash
   # Approve
   cast send $XAUT "approve(address,uint256)" $BORROWING_PROTOCOL_V2 10000000 \
     --rpc-url $MANTLE_SEPOLIA_RPC \
     --private-key $USER_PRIVATE_KEY

   # Deposit and borrow
   cast send $BORROWING_PROTOCOL_V2 "depositAndBorrow(uint256,uint256)" 10000000 40000000000000 \
     --rpc-url $MANTLE_SEPOLIA_RPC \
     --private-key $USER_PRIVATE_KEY
   ```
