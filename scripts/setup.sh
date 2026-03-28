#!/bin/bash

echo "🚀 RaylsFi Setup Script"
echo "======================="
echo ""

# Check if foundry is installed
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry not found. Please install it first:"
    echo "   curl -L https://foundry.paradigm.xyz | bash"
    echo "   foundryup"
    exit 1
fi

echo "✅ Foundry installed"

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env and add your DEPLOYER_PRIVATE_KEY"
    echo ""
    echo "Generate a new wallet with:"
    echo "  cast wallet new"
    echo ""
else
    echo "✅ .env file exists"
fi

# Install dependencies
echo "📦 Installing Foundry dependencies..."
forge install

# Build contracts
echo "🔨 Building contracts..."
forge build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Edit .env and add your DEPLOYER_PRIVATE_KEY"
    echo "2. Get testnet tokens from the faucet or contact Nuno"
    echo "3. Deploy to public chain: ./scripts/deploy-public.sh"
    echo "4. Deploy to privacy node: ./scripts/deploy-privacy.sh"
    echo ""
    echo "📖 See DEPLOYMENT.md for detailed instructions"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
