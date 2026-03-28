#!/bin/bash

set -e

source .env

echo "Deploying to Rayls Public Chain (Testnet)..."
echo "RPC URL: $PUBLIC_CHAIN_RPC_URL"
echo "Chain ID: $PUBLIC_CHAIN_ID"

forge script scripts/DeployPublicChain.s.sol:DeployPublicChain \
    --rpc-url $PUBLIC_CHAIN_RPC_URL \
    --broadcast \
    --verify \
    -vvvv

echo ""
echo "Deployment complete! Check the output above for contract addresses."
echo "Save these addresses to your .env file for future use."
