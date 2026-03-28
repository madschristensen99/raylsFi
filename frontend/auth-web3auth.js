// Rayls.Fi Authentication with Web3Auth
// Social login (Google, Twitter, Discord, Email) - VANILLA JS THAT ACTUALLY WORKS

class RaylsWeb3Auth {
  constructor() {
    this.web3auth = null;
    this.provider = null;
    this.address = null;
    this.user = null;
    this.isAuthenticated = false;
  }

  async init() {
    console.log('🔐 Initializing Web3Auth social authentication...');

    try {
      const { Web3Auth } = window.Modal;
      const { CHAIN_NAMESPACES, WEB3AUTH_NETWORK } = window.Base;
      const { EthereumPrivateKeyProvider } = window.EthereumProvider;

      // Configure Ethereum provider for Rayls Public Chain
      const chainConfig = {
        chainNamespace: "eip155",
        chainId: "0x6F4C77", // 7295799 in hex
        rpcTarget: "https://testnet-rpc.rayls.com/",
        displayName: "Rayls Public Testnet",
        blockExplorerUrl: "https://testnet-explorer.rayls.com/",
        ticker: "USDr",
        tickerName: "USDr",
      };

      const privateKeyProvider = new EthereumPrivateKeyProvider({
        config: { chainConfig }
      });

      // Initialize Web3Auth
      this.web3auth = new Web3Auth({
        clientId: "BNAILIB4zmrCw3yBoVrLD1OH4f7pjjjyFtd7yukDrL9KE0vIsjL5GeK9QOmp3txislAi9qKx3kEBc-v-1V_GPiU",
        web3AuthNetwork: "sapphire_mainnet",
        chainConfig,
        uiConfig: {
          appName: "Rayls.Fi",
          theme: {
            primary: "#6eff9e",
            gray: "#0c0c10",
            red: "#ff6b6b",
            white: "#e8e6f0",
          },
          mode: "dark",
          logoLight: "https://rayls.fi/logo.png",
          logoDark: "https://rayls.fi/logo.png",
          defaultLanguage: "en",
          loginMethodsOrder: ["google", "twitter", "discord", "email_passwordless"],
        },
      });

      await this.web3auth.init();

      // Check if already connected
      if (this.web3auth.connected) {
        await this.handleConnection();
      }

      this.setupUI();
      console.log('✅ Web3Auth initialized - social login ready!');
    } catch (error) {
      console.error('❌ Web3Auth initialization failed:', error);
      this.useFallback();
    }
  }

  async handleConnection() {
    try {
      this.provider = this.web3auth.provider;
      
      if (!this.provider) {
        throw new Error('No provider');
      }

      // Get user info
      this.user = await this.web3auth.getUserInfo();
      console.log('✅ User info:', this.user);

      // Get wallet address
      const ethersProvider = new ethers.providers.Web3Provider(this.provider);
      const signer = ethersProvider.getSigner();
      this.address = await signer.getAddress();
      this.isAuthenticated = true;

      console.log('✅ Connected:', this.address);
      console.log('📧 Email:', this.user.email);
      console.log('👤 Name:', this.user.name);

      this.updateUI();

      // Dispatch auth event
      window.dispatchEvent(new CustomEvent('raylsfi-auth-change', {
        detail: {
          isAuthenticated: true,
          wallet: this.address,
          user: this.user
        }
      }));
    } catch (error) {
      console.error('Connection handling failed:', error);
    }
  }

  async login() {
    if (!this.web3auth) {
      console.error('Web3Auth not initialized');
      return;
    }

    try {
      const web3authProvider = await this.web3auth.connect();
      
      if (web3authProvider) {
        await this.handleConnection();
      }
    } catch (error) {
      console.error('Login failed:', error);
    }
  }

  async logout() {
    if (!this.web3auth) return;

    try {
      await this.web3auth.logout();
      
      this.provider = null;
      this.address = null;
      this.user = null;
      this.isAuthenticated = false;

      console.log('🔓 Logged out');
      this.updateUI();

      window.dispatchEvent(new CustomEvent('raylsfi-auth-change', {
        detail: {
          isAuthenticated: false,
          wallet: null,
          user: null
        }
      }));
    } catch (error) {
      console.error('Logout failed:', error);
    }
  }

  setupUI() {
    const authButton = document.getElementById('authButton');
    if (!authButton) return;

    authButton.onclick = async () => {
      if (this.isAuthenticated) {
        await this.logout();
      } else {
        await this.login();
      }
    };
  }

  updateUI() {
    const authButton = document.getElementById('authButton');
    if (!authButton) return;

    if (this.isAuthenticated) {
      // Show email or name if available, otherwise wallet address
      const displayName = this.user?.email || 
                         this.user?.name ||
                         (this.address ? `${this.address.slice(0, 6)}...${this.address.slice(-4)}` : 'User');
      authButton.textContent = displayName;
    } else {
      authButton.textContent = 'Sign In';
    }
  }

  async getContract(address, abi) {
    if (!this.provider) {
      throw new Error('Not authenticated');
    }
    
    const ethersProvider = new ethers.providers.Web3Provider(this.provider);
    const signer = ethersProvider.getSigner();
    return new ethers.Contract(address, abi, signer);
  }

  async signMessage(message) {
    if (!this.provider) {
      throw new Error('Not authenticated');
    }
    
    const ethersProvider = new ethers.providers.Web3Provider(this.provider);
    const signer = ethersProvider.getSigner();
    return await signer.signMessage(message);
  }

  async sendTransaction(tx) {
    if (!this.provider) {
      throw new Error('Not authenticated');
    }
    
    const ethersProvider = new ethers.providers.Web3Provider(this.provider);
    const signer = ethersProvider.getSigner();
    return await signer.sendTransaction(tx);
  }

  async switchToRaylsPublic() {
    if (!this.provider) return;
    
    try {
      await this.provider.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x6F4C77' }],
      });
      console.log('✅ Switched to Rayls Public Testnet');
    } catch (error) {
      console.error('Network switch failed:', error);
    }
  }

  async switchToPrivacyNode() {
    if (!this.provider) return;
    
    try {
      await this.provider.request({
        method: 'wallet_addEthereumChain',
        params: [{
          chainId: '0xC3502',
          chainName: 'Rayls Privacy Node',
          rpcUrls: ['https://privacy-node-2.rayls.com'],
          nativeCurrency: {
            name: 'USDr',
            symbol: 'USDr',
            decimals: 18,
          },
          blockExplorerUrls: ['https://privacy-node-2-explorer.rayls.com'],
        }],
      });
      console.log('✅ Switched to Rayls Privacy Node');
    } catch (error) {
      console.error('Network switch failed:', error);
    }
  }

  // Fallback to MetaMask if Web3Auth fails
  useFallback() {
    console.log('📱 Using fallback MetaMask authentication');
    
    const authButton = document.getElementById('authButton');
    if (!authButton) return;

    authButton.textContent = 'Connect Wallet';
    authButton.onclick = async () => {
      if (!window.ethereum) {
        alert('Please install MetaMask or refresh to try social login again');
        window.open('https://metamask.io/download/', '_blank');
        return;
      }

      try {
        const accounts = await window.ethereum.request({ 
          method: 'eth_requestAccounts' 
        });
        
        this.address = accounts[0];
        this.provider = window.ethereum;
        this.isAuthenticated = true;

        authButton.textContent = `${this.address.slice(0, 6)}...${this.address.slice(-4)}`;
        
        window.dispatchEvent(new CustomEvent('raylsfi-auth-change', {
          detail: {
            isAuthenticated: true,
            wallet: this.address
          }
        }));
      } catch (error) {
        console.error('Connection failed:', error);
      }
    };
  }
}

// Global instance
window.raylsAuth = new RaylsWeb3Auth();

// Initialize on load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => window.raylsAuth.init());
} else {
  window.raylsAuth.init();
}
