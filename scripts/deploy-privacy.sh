#!/bin/bash

set -e

source .env

echo "Deploying to Rayls Privacy Node..."
echo "RPC URL: $PRIVACY_NODE_RPC_URL"
echo "Chain ID: $PRIVACY_NODE_CHAIN_ID"

forge script scripts/DeployPrivacyNode.s.sol:DeployPrivacyNode \
    --rpc-url $PRIVACY_NODE_RPC_URL \
    --broadcast \
    -vvvv

echo ""
echo "Deployment complete! Check the output above for contract addresses."
echo "Save these addresses to your .env file for future use."
