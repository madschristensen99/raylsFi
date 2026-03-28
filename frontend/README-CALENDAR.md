# Google Calendar Integration for Rayls.Fi

## Overview

The Rayls.Fi app now includes Google Calendar integration that leverages your existing Google OAuth authentication flow through Web3Auth. The AI agent can now manage your calendar alongside your finances.

## Features

### Calendar Management
- **View Events**: Check today's schedule, tomorrow's events, or upcoming appointments
- **Create Events**: Schedule meetings and events using natural language
- **Search Events**: Find specific events by keyword
- **Check Availability**: See when you're free or busy

### AI Agent Commands

The agent understands natural language calendar queries:

**View Schedule:**
- "What's on my calendar today?"
- "Show me tomorrow's events"
- "What are my upcoming meetings?"

**Create Events:**
- "Schedule meeting with John tomorrow at 2pm"
- "Create event called 'Team Standup' on Monday at 10am"
- "Add appointment for Friday at 3pm"

**Search:**
- "Find events about project review"
- "Search for meetings with Sarah"

**Availability:**
- "Am I free this afternoon?"
- "When is my next meeting?"

## Architecture

### Files Added

1. **`calendar-integration.js`**
   - Core Google Calendar API wrapper
   - Handles OAuth token management
   - Provides methods for CRUD operations on events
   - Manages free/busy queries

2. **`agent-calendar.js`**
   - AI agent calendar command handler
   - Natural language parsing for calendar operations
   - Formats calendar responses for the chat interface
   - Integrates with existing agent system

### Integration Points

The calendar system integrates seamlessly with your existing auth:

```javascript
// Web3Auth provides Google OAuth
window.raylsAuth.init() 
  ↓
// Calendar picks up the OAuth token
window.raylsCalendar.init()
  ↓
// Agent gains calendar capabilities
window.agentCalendar.init()
```

## How It Works

### 1. Authentication Flow

When you sign in with Google through Web3Auth:
- Web3Auth handles the OAuth flow
- The calendar integration automatically requests Calendar API access
- Your OAuth token is used for Calendar API calls
- No additional login required

### 2. Agent Integration

The AI agent now checks if messages are calendar-related:

```javascript
async function sendAgentMessage(text) {
  // Check if calendar command
  if (window.agentCalendar.isCalendarCommand(text)) {
    const response = await window.agentCalendar.handleCalendarCommand(text);
    // Display calendar results
  } else {
    // Handle financial queries
  }
}
```

### 3. Calendar API Access

All calendar operations use the Google Calendar API v3:

```javascript
// Example: Get upcoming events
const events = await window.raylsCalendar.getUpcomingEvents(10);

// Example: Create event
await window.raylsCalendar.createEvent({
  title: "Team Meeting",
  startTime: new Date("2026-03-29T14:00:00").toISOString(),
  endTime: new Date("2026-03-29T15:00:00").toISOString()
});
```

## API Reference

### RaylsCalendar Class

**Methods:**

- `getUpcomingEvents(maxResults, timeMin)` - Fetch upcoming events
- `createEvent(eventDetails)` - Create a new calendar event
- `updateEvent(eventId, updates)` - Update an existing event
- `deleteEvent(eventId)` - Delete an event
- `searchEvents(query, maxResults)` - Search for events by keyword
- `getFreeBusy(timeMin, timeMax, calendars)` - Check availability
- `formatEvent(event)` - Format event for display

### AgentCalendarHandler Class

**Methods:**

- `handleCalendarCommand(message)` - Process natural language calendar commands
- `isCalendarCommand(message)` - Check if message is calendar-related
- `getUpcomingEvents()` - Get next 5 events
- `getTodayEvents()` - Get today's schedule
- `getTomorrowEvents()` - Get tomorrow's schedule
- `createEventFromMessage(message)` - Parse and create event from text
- `searchEventsFromMessage(message)` - Parse and search events
- `checkAvailability(message)` - Check free/busy status

## Privacy & Security

- **OAuth Scopes**: Only requests necessary calendar permissions
- **Token Management**: Tokens are managed securely by Web3Auth
- **No Storage**: Calendar data is fetched on-demand, not stored locally
- **User Control**: Users can revoke calendar access anytime through Google settings

## Example Usage

### In the Agent Chat

```
User: What's on my calendar today?
Agent: You have 3 events today:

1. **Team Standup**
   🕐 9:00 AM
   📍 Conference Room A

2. **Client Call**
   🕐 2:00 PM
   📍 Zoom

3. **Code Review**
   🕐 4:30 PM
```

```
User: Schedule meeting with Sarah tomorrow at 3pm
Agent: ✅ Event created: **Meeting with Sarah**
📅 March 29, 2026 at 3:00 PM
🔗 [View in Calendar](https://calendar.google.com/...)
```

## Future Enhancements

Potential additions:
- Calendar event reminders integrated with financial goals
- Automatic expense tracking from calendar events
- Meeting cost calculator based on attendees
- Smart scheduling suggestions based on financial priorities
- Integration with travel expenses and reimbursements

## Troubleshooting

**Calendar not working?**
1. Make sure you're signed in with Google
2. Check that you granted calendar permissions during login
3. Verify your Google account has Calendar enabled
4. Check browser console for API errors

**Need to re-authorize?**
- Sign out and sign back in with Google
- Web3Auth will re-request necessary permissions

## Technical Notes

- Uses Google Calendar API v3
- Requires active internet connection
- OAuth token automatically refreshed by Web3Auth
- All times use user's local timezone by default
- Supports recurring events (read-only for now)
