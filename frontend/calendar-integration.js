// Google Calendar Integration for Rayls.Fi
// Demo mode with simulated calendar data until OAuth scopes are configured

class RaylsCalendar {
  constructor() {
    this.accessToken = null;
    this.isCalendarEnabled = false;
    this.calendarId = 'primary';
    this.demoMode = true; // Use demo data until real OAuth is configured
    this.demoEvents = this.generateDemoEvents();
  }

  async init() {
    console.log('📅 Initializing Google Calendar integration...');
    
    // Listen for auth changes
    window.addEventListener('raylsfi-auth-change', async (event) => {
      if (event.detail.isAuthenticated && event.detail.user) {
        await this.handleAuthChange(event.detail.user);
      } else {
        this.accessToken = null;
        this.isCalendarEnabled = false;
      }
    });
  }

  generateDemoEvents() {
    const now = new Date();
    const events = [];
    
    // Today's events
    const today9am = new Date(now);
    today9am.setHours(9, 0, 0, 0);
    events.push({
      id: 'demo-1',
      summary: 'Team Standup',
      description: 'Daily team sync',
      start: { dateTime: today9am.toISOString() },
      end: { dateTime: new Date(today9am.getTime() + 30 * 60000).toISOString() },
      location: 'Conference Room A',
      htmlLink: '#'
    });
    
    const today2pm = new Date(now);
    today2pm.setHours(14, 0, 0, 0);
    events.push({
      id: 'demo-2',
      summary: 'Client Call',
      description: 'Q1 review with client',
      start: { dateTime: today2pm.toISOString() },
      end: { dateTime: new Date(today2pm.getTime() + 60 * 60000).toISOString() },
      location: 'Zoom',
      htmlLink: '#'
    });
    
    // Tomorrow's events
    const tomorrow10am = new Date(now);
    tomorrow10am.setDate(tomorrow10am.getDate() + 1);
    tomorrow10am.setHours(10, 0, 0, 0);
    events.push({
      id: 'demo-3',
      summary: 'Project Planning',
      description: 'Sprint planning session',
      start: { dateTime: tomorrow10am.toISOString() },
      end: { dateTime: new Date(tomorrow10am.getTime() + 120 * 60000).toISOString() },
      location: 'Office',
      htmlLink: '#'
    });
    
    return events;
  }

  async handleAuthChange(user) {
    try {
      if (window.raylsAuth && window.raylsAuth.user) {
        // Enable demo mode for authenticated users
        this.isCalendarEnabled = true;
        this.demoMode = true;
        
        console.log('📅 Calendar demo mode enabled');
        console.log('ℹ️ Using simulated calendar data');
        console.log('💡 To enable real Google Calendar:');
        console.log('   1. Configure Web3Auth with calendar scopes');
        console.log('   2. Add: https://www.googleapis.com/auth/calendar');
        console.log('   3. Implement OAuth token exchange');
        
        // Dispatch calendar ready event
        window.dispatchEvent(new CustomEvent('raylsfi-calendar-ready', {
          detail: { 
            enabled: true,
            demoMode: true
          }
        }));
      }
    } catch (error) {
      console.error('Calendar initialization error:', error);
      this.isCalendarEnabled = false;
    }
  }

  async requestCalendarAccess() {
    try {
      // Request additional calendar permissions
      // This will prompt user to grant calendar access
      const response = await gapi.client.request({
        path: '/calendar/v3/users/me/calendarList',
        method: 'GET'
      });
      
      this.isCalendarEnabled = true;
      console.log('✅ Calendar access granted');
      return true;
    } catch (error) {
      console.error('Calendar access denied:', error);
      return false;
    }
  }

  // Get upcoming events
  async getUpcomingEvents(maxResults = 10, timeMin = new Date()) {
    if (!this.isCalendarEnabled) {
      throw new Error('Calendar not enabled. Please authenticate first.');
    }

    // Use demo data in demo mode
    if (this.demoMode) {
      const upcoming = this.demoEvents.filter(event => {
        const eventStart = new Date(event.start.dateTime);
        return eventStart >= timeMin;
      }).sort((a, b) => {
        return new Date(a.start.dateTime) - new Date(b.start.dateTime);
      }).slice(0, maxResults);
      
      return upcoming;
    }

    try {
      const response = await fetch(
        `https://www.googleapis.com/calendar/v3/calendars/${this.calendarId}/events?` +
        new URLSearchParams({
          maxResults: maxResults,
          timeMin: timeMin.toISOString(),
          singleEvents: true,
          orderBy: 'startTime'
        }), {
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        throw new Error(`Calendar API error: ${response.status}`);
      }

      const data = await response.json();
      return data.items || [];
    } catch (error) {
      console.error('Error fetching events:', error);
      throw error;
    }
  }

  // Create a new calendar event
  async createEvent(eventDetails) {
    if (!this.isCalendarEnabled) {
      throw new Error('Calendar not enabled. Please authenticate first.');
    }

    const event = {
      id: `demo-${Date.now()}`,
      summary: eventDetails.title,
      description: eventDetails.description || 'Created by Rayls.Fi AI Agent',
      start: {
        dateTime: eventDetails.startTime,
        timeZone: eventDetails.timeZone || Intl.DateTimeFormat().resolvedOptions().timeZone
      },
      end: {
        dateTime: eventDetails.endTime,
        timeZone: eventDetails.timeZone || Intl.DateTimeFormat().resolvedOptions().timeZone
      },
      attendees: eventDetails.attendees || [],
      location: eventDetails.location || '',
      htmlLink: '#',
      reminders: {
        useDefault: false,
        overrides: [
          { method: 'email', minutes: 24 * 60 },
          { method: 'popup', minutes: 30 }
        ]
      }
    };

    // Use demo mode
    if (this.demoMode) {
      this.demoEvents.push(event);
      console.log('✅ Demo event created:', event.summary);
      return event;
    }

    try {
      const response = await fetch(
        `https://www.googleapis.com/calendar/v3/calendars/${this.calendarId}/events`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(event)
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to create event: ${response.status}`);
      }

      const data = await response.json();
      console.log('✅ Event created:', data.htmlLink);
      return data;
    } catch (error) {
      console.error('Error creating event:', error);
      throw error;
    }
  }

  // Update an existing event
  async updateEvent(eventId, updates) {
    if (!this.isCalendarEnabled) {
      throw new Error('Calendar not enabled. Please authenticate first.');
    }

    try {
      // First get the existing event
      const getResponse = await fetch(
        `https://www.googleapis.com/calendar/v3/calendars/${this.calendarId}/events/${eventId}`,
        {
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!getResponse.ok) {
        throw new Error(`Event not found: ${getResponse.status}`);
      }

      const existingEvent = await getResponse.json();

      // Merge updates
      const updatedEvent = {
        ...existingEvent,
        summary: updates.title || existingEvent.summary,
        description: updates.description || existingEvent.description,
        start: updates.startTime ? {
          dateTime: updates.startTime,
          timeZone: updates.timeZone || existingEvent.start.timeZone
        } : existingEvent.start,
        end: updates.endTime ? {
          dateTime: updates.endTime,
          timeZone: updates.timeZone || existingEvent.end.timeZone
        } : existingEvent.end
      };

      const response = await fetch(
        `https://www.googleapis.com/calendar/v3/calendars/${this.calendarId}/events/${eventId}`,
        {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(updatedEvent)
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to update event: ${response.status}`);
      }

      const data = await response.json();
      console.log('✅ Event updated:', data.htmlLink);
      return data;
    } catch (error) {
      console.error('Error updating event:', error);
      throw error;
    }
  }

  // Delete an event
  async deleteEvent(eventId) {
    if (!this.isCalendarEnabled) {
      throw new Error('Calendar not enabled. Please authenticate first.');
    }

    try {
      const response = await fetch(
        `https://www.googleapis.com/calendar/v3/calendars/${this.calendarId}/events/${eventId}`,
        {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok && response.status !== 410) {
        throw new Error(`Failed to delete event: ${response.status}`);
      }

      console.log('✅ Event deleted');
      return true;
    } catch (error) {
      console.error('Error deleting event:', error);
      throw error;
    }
  }

  // Search for events
  async searchEvents(query, maxResults = 10) {
    if (!this.isCalendarEnabled) {
      throw new Error('Calendar not enabled. Please authenticate first.');
    }

    // Use demo mode
    if (this.demoMode) {
      const lowerQuery = query.toLowerCase();
      const results = this.demoEvents.filter(event => {
        return event.summary.toLowerCase().includes(lowerQuery) ||
               (event.description && event.description.toLowerCase().includes(lowerQuery)) ||
               (event.location && event.location.toLowerCase().includes(lowerQuery));
      }).slice(0, maxResults);
      
      return results;
    }

    try {
      const response = await fetch(
        `https://www.googleapis.com/calendar/v3/calendars/${this.calendarId}/events?` +
        new URLSearchParams({
          q: query,
          maxResults: maxResults,
          singleEvents: true,
          orderBy: 'startTime'
        }), {
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        throw new Error(`Search failed: ${response.status}`);
      }

      const data = await response.json();
      return data.items || [];
    } catch (error) {
      console.error('Error searching events:', error);
      throw error;
    }
  }

  // Get free/busy information
  async getFreeBusy(timeMin, timeMax, calendars = ['primary']) {
    if (!this.isCalendarEnabled) {
      throw new Error('Calendar not enabled. Please authenticate first.');
    }

    try {
      const response = await fetch(
        'https://www.googleapis.com/calendar/v3/freeBusy',
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            timeMin: timeMin.toISOString(),
            timeMax: timeMax.toISOString(),
            items: calendars.map(id => ({ id }))
          })
        }
      );

      if (!response.ok) {
        throw new Error(`Free/busy query failed: ${response.status}`);
      }

      const data = await response.json();
      return data.calendars;
    } catch (error) {
      console.error('Error getting free/busy:', error);
      throw error;
    }
  }

  // Format event for display
  formatEvent(event) {
    const start = new Date(event.start.dateTime || event.start.date);
    const end = new Date(event.end.dateTime || event.end.date);
    
    return {
      id: event.id,
      title: event.summary || 'Untitled Event',
      description: event.description || '',
      startTime: start,
      endTime: end,
      startFormatted: start.toLocaleString(),
      endFormatted: end.toLocaleString(),
      link: event.htmlLink,
      location: event.location || '',
      attendees: event.attendees || []
    };
  }
}

// Global instance
window.raylsCalendar = new RaylsCalendar();

// Initialize on load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => window.raylsCalendar.init());
} else {
  window.raylsCalendar.init();
}
