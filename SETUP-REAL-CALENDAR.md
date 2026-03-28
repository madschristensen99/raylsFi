# Setup Real Google Calendar Integration

Currently, the calendar integration uses **demo data**. To connect to your actual Google Calendar, follow these steps:

## Prerequisites

You need a Google Cloud Project with Calendar API enabled.

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Google Calendar API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

## Step 2: Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "Web application"
4. Add authorized JavaScript origins:
   ```
   http://localhost:8000
   http://localhost:3000
   http://127.0.0.1:8000
   https://yourdomain.com
   ```
5. Add authorized redirect URIs (same as origins)
6. Click "Create"
7. Copy your **Client ID**

## Step 3: Create API Key

1. In "Credentials", click "Create Credentials" > "API Key"
2. Copy your **API Key**
3. (Optional) Restrict the key to Calendar API only

## Step 4: Update the Code

### Option A: Using the New Google OAuth Flow (Recommended)

1. Open `frontend/google-oauth-calendar.js`
2. Replace the placeholder values:
   ```javascript
   this.CLIENT_ID = 'YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com';
   this.API_KEY = 'YOUR_ACTUAL_API_KEY';
   ```

3. Add the script to `index.html`:
   ```html
   <script src="google-oauth-calendar.js"></script>
   ```

4. Add a "Connect Calendar" button to your UI (see below)

### Option B: Configure Web3Auth with Calendar Scopes

This is more complex and requires Web3Auth custom authentication:

1. Contact Web3Auth support to add custom OAuth scopes
2. Configure your Web3Auth dashboard with Google Calendar scopes
3. Update `auth-web3auth.js` to request calendar permissions

## Step 5: Add UI Button

Add this button to your app interface (in `index.html`):

```html
<!-- Add near the agent panel -->
<button id="connectCalendarBtn" class="calendar-connect-btn" style="display:none;">
  📅 Connect Real Calendar
</button>

<style>
.calendar-connect-btn {
  position: fixed;
  bottom: 100px;
  right: 28px;
  z-index: 250;
  padding: 12px 24px;
  background: var(--accent);
  color: var(--bg);
  border: none;
  border-radius: 8px;
  font-family: 'DM Mono', monospace;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 4px 24px rgba(110, 255, 158, 0.25);
  transition: all 0.3s;
}

.calendar-connect-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 32px rgba(110, 255, 158, 0.35);
}
</style>

<script>
// Show button when authenticated
window.addEventListener('raylsfi-auth-change', (event) => {
  if (event.detail.isAuthenticated) {
    document.getElementById('connectCalendarBtn').style.display = 'block';
  }
});

// Handle button click
document.getElementById('connectCalendarBtn').addEventListener('click', () => {
  if (window.googleCalendarAuth) {
    window.googleCalendarAuth.requestCalendarAccess();
  }
});

// Hide button when calendar is connected
window.addEventListener('raylsfi-calendar-ready', (event) => {
  if (event.detail.enabled && !event.detail.demoMode) {
    document.getElementById('connectCalendarBtn').style.display = 'none';
  }
});
</script>
```

## Step 6: Test the Integration

1. Sign in with Google (Web3Auth)
2. Click "Connect Real Calendar" button
3. Grant calendar permissions in the Google popup
4. Ask the agent: "What's on my calendar today?"
5. You should now see your real calendar events!

## Security Notes

- **Never commit your API keys to Git**
- Use environment variables in production
- Restrict API key to your domain
- Consider implementing a backend proxy for token management
- Tokens expire - implement refresh logic

## Troubleshooting

### "Calendar not connected" error
- Make sure you clicked "Connect Real Calendar"
- Check browser console for errors
- Verify your Client ID and API Key are correct

### "Access denied" error
- Make sure Calendar API is enabled in Google Cloud
- Check that your domain is in authorized origins
- Try revoking and re-granting permissions

### Still seeing demo data
- Check `window.raylsCalendar.demoMode` in console (should be `false`)
- Verify `window.raylsCalendar.accessToken` exists
- Refresh the page after granting permissions

## Alternative: Backend Proxy (Production)

For production, consider this architecture:

```
User → Web3Auth (wallet) → Your Backend → Google Calendar API
                              ↓
                         Store OAuth tokens
                         Handle refresh
                         Proxy requests
```

This is more secure and allows you to:
- Keep API keys server-side
- Implement proper token refresh
- Add rate limiting
- Cache calendar data
- Add additional security layers

## Current Status

✅ Demo mode working  
⚠️ Real calendar requires setup  
📝 Follow steps above to enable  

Once configured, the agent will automatically use real calendar data instead of demo events.
