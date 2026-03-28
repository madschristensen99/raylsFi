#!/bin/bash

# Deploy PlaytestVault to Rayls Public Testnet

source .env

echo "🚀 Deploying PlaytestVault to Rayls Public Testnet..."

forge script scripts/DeployPlaytest.s.sol:DeployPlaytest \
    --rpc-url $PUBLIC_CHAIN_RPC_URL \
    --broadcast \
    --legacy \
    -vvv

echo "✅ PlaytestVault deployment complete!"
