// Direct Google OAuth for Calendar API Access
// This runs alongside Web3Auth to get proper Calendar permissions

class GoogleCalendarAuth {
  constructor() {
    this.CLIENT_ID = '755015013964-bb7ea1t57fvogg7mo0i6ainu6fghtlc3.apps.googleusercontent.com';
    this.API_KEY = 'AIzaSyAy417e-tSRx2rpfXG5CHjMjYnViXLx6PI';
    this.DISCOVERY_DOC = 'https://www.googleapis.com/discovery/v1/apis/calendar/v3/rest';
    this.SCOPES = 'https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/calendar.events';
    
    this.tokenClient = null;
    this.gapiInited = false;
    this.gisInited = false;
    this.accessToken = null;
  }

  async init() {
    console.log('🔑 Initializing Google Calendar OAuth...');
    
    // Load Google API scripts
    await this.loadGoogleScripts();
    
    // Initialize Google API
    await this.initializeGoogleAPI();
    
    // Initialize Google Identity Services
    await this.initializeGIS();
  }

  loadGoogleScripts() {
    return new Promise((resolve) => {
      // Load GAPI
      if (!document.getElementById('gapi-script')) {
        const gapiScript = document.createElement('script');
        gapiScript.id = 'gapi-script';
        gapiScript.src = 'https://apis.google.com/js/api.js';
        gapiScript.onload = () => {
          // Load GIS
          const gisScript = document.createElement('script');
          gisScript.id = 'gis-script';
          gisScript.src = 'https://accounts.google.com/gsi/client';
          gisScript.onload = resolve;
          document.head.appendChild(gisScript);
        };
        document.head.appendChild(gapiScript);
      } else {
        resolve();
      }
    });
  }

  async initializeGoogleAPI() {
    return new Promise((resolve) => {
      gapi.load('client', async () => {
        await gapi.client.init({
          apiKey: this.API_KEY,
          discoveryDocs: [this.DISCOVERY_DOC],
        });
        this.gapiInited = true;
        console.log('✅ Google API initialized');
        resolve();
      });
    });
  }

  async initializeGIS() {
    this.tokenClient = google.accounts.oauth2.initTokenClient({
      client_id: this.CLIENT_ID,
      scope: this.SCOPES,
      callback: (response) => {
        if (response.error !== undefined) {
          console.error('OAuth error:', response);
          return;
        }
        this.accessToken = response.access_token;
        console.log('✅ Calendar access granted');
        
        // Update calendar integration
        if (window.raylsCalendar) {
          window.raylsCalendar.accessToken = this.accessToken;
          window.raylsCalendar.demoMode = false;
          window.raylsCalendar.isCalendarEnabled = true;
          
          window.dispatchEvent(new CustomEvent('raylsfi-calendar-ready', {
            detail: { 
              enabled: true,
              demoMode: false
            }
          }));
        }
      },
    });
    this.gisInited = true;
    console.log('✅ Google Identity Services initialized');
  }

  requestCalendarAccess() {
    if (!this.tokenClient) {
      console.error('Token client not initialized');
      return;
    }

    // Check if we already have a token
    if (this.accessToken) {
      console.log('Already have calendar access');
      return;
    }

    // Request access token
    this.tokenClient.requestAccessToken({ prompt: 'consent' });
  }

  revokeAccess() {
    if (this.accessToken) {
      google.accounts.oauth2.revoke(this.accessToken, () => {
        this.accessToken = null;
        console.log('Calendar access revoked');
      });
    }
  }
}

// Global instance
window.googleCalendarAuth = new GoogleCalendarAuth();

// Initialize when authenticated with Web3Auth
window.addEventListener('raylsfi-auth-change', async (event) => {
  if (event.detail.isAuthenticated) {
    // Initialize Google Calendar OAuth
    await window.googleCalendarAuth.init();
    console.log('💡 Click "Connect Calendar" to enable real Google Calendar access');
  }
});
