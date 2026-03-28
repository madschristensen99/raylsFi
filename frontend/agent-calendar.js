// AI Agent Calendar Integration
// Extends the AI agent with calendar capabilities

class AgentCalendarHandler {
  constructor() {
    this.calendar = null;
    this.isReady = false;
  }

  init() {
    // Wait for calendar to be ready
    window.addEventListener('raylsfi-calendar-ready', (event) => {
      if (event.detail.enabled) {
        this.calendar = window.raylsCalendar;
        this.isReady = true;
        console.log('🤖 Agent calendar capabilities enabled');
      }
    });
  }

  // Parse natural language calendar commands
  async handleCalendarCommand(message) {
    if (!this.isReady) {
      return {
        type: 'error',
        message: 'Calendar not connected. Please sign in with Google first.'
      };
    }

    const lowerMessage = message.toLowerCase().trim();

    try {
      // Single word "calendar" - show help
      if (lowerMessage === 'calendar') {
        return {
          type: 'calendar',
          message: `📅 **Calendar Commands**\n\nI can help you with:\n\n• "What's on my calendar today?"\n• "Show tomorrow's events"\n• "What are my upcoming meetings?"\n• "Schedule meeting tomorrow at 2pm"\n• "Find events about [topic]"\n• "Am I free this afternoon?"\n\nWhat would you like to know?`,
          events: []
        };
      }

      // Check upcoming events
      if ((lowerMessage.includes('what') || lowerMessage.includes('show')) && 
          (lowerMessage.includes('next') || lowerMessage.includes('upcoming') || lowerMessage.includes('schedule'))) {
        return await this.getUpcomingEvents();
      }

      // Check today's events - more flexible matching
      if (lowerMessage.includes('today') || 
          (lowerMessage.includes('what') && lowerMessage.includes('on')) ||
          lowerMessage === "today's schedule" ||
          lowerMessage === "today's events") {
        return await this.getTodayEvents();
      }

      // Check tomorrow's events
      if (lowerMessage.includes('tomorrow')) {
        return await this.getTomorrowEvents();
      }

      // Create event
      if (lowerMessage.includes('create') || lowerMessage.includes('schedule') || lowerMessage.includes('add')) {
        if (lowerMessage.includes('event') || lowerMessage.includes('meeting')) {
          return await this.createEventFromMessage(message);
        }
      }

      // Search events
      if (lowerMessage.includes('find') || lowerMessage.includes('search')) {
        return await this.searchEventsFromMessage(message);
      }

      // Check if free
      if (lowerMessage.includes('free') || lowerMessage.includes('available')) {
        return await this.checkAvailability(message);
      }

      return null; // Not a calendar command
    } catch (error) {
      return {
        type: 'error',
        message: `Calendar error: ${error.message}`
      };
    }
  }

  async getUpcomingEvents() {
    try {
      const events = await this.calendar.getUpcomingEvents(5);
      
      if (events.length === 0) {
        return {
          type: 'calendar',
          message: 'You have no upcoming events.',
          events: []
        };
      }

      const formattedEvents = events.map(e => this.calendar.formatEvent(e));
      const eventList = formattedEvents.map((e, i) => 
        `${i + 1}. **${e.title}**\n   📅 ${e.startFormatted}\n   ${e.location ? `📍 ${e.location}` : ''}`
      ).join('\n\n');

      return {
        type: 'calendar',
        message: `Here are your next ${events.length} events:\n\n${eventList}`,
        events: formattedEvents
      };
    } catch (error) {
      throw error;
    }
  }

  async getTodayEvents() {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const events = await this.calendar.getUpcomingEvents(20, today);
      const todayEvents = events.filter(e => {
        const start = new Date(e.start.dateTime || e.start.date);
        return start >= today && start < tomorrow;
      });

      if (todayEvents.length === 0) {
        return {
          type: 'calendar',
          message: 'You have no events scheduled for today.',
          events: []
        };
      }

      const formattedEvents = todayEvents.map(e => this.calendar.formatEvent(e));
      const eventList = formattedEvents.map((e, i) => 
        `${i + 1}. **${e.title}**\n   🕐 ${new Date(e.startTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}\n   ${e.location ? `📍 ${e.location}` : ''}`
      ).join('\n\n');

      return {
        type: 'calendar',
        message: `You have ${todayEvents.length} event${todayEvents.length > 1 ? 's' : ''} today:\n\n${eventList}`,
        events: formattedEvents
      };
    } catch (error) {
      throw error;
    }
  }

  async getTomorrowEvents() {
    try {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);
      
      const dayAfter = new Date(tomorrow);
      dayAfter.setDate(dayAfter.getDate() + 1);

      const events = await this.calendar.getUpcomingEvents(20, tomorrow);
      const tomorrowEvents = events.filter(e => {
        const start = new Date(e.start.dateTime || e.start.date);
        return start >= tomorrow && start < dayAfter;
      });

      if (tomorrowEvents.length === 0) {
        return {
          type: 'calendar',
          message: 'You have no events scheduled for tomorrow.',
          events: []
        };
      }

      const formattedEvents = tomorrowEvents.map(e => this.calendar.formatEvent(e));
      const eventList = formattedEvents.map((e, i) => 
        `${i + 1}. **${e.title}**\n   🕐 ${new Date(e.startTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}\n   ${e.location ? `📍 ${e.location}` : ''}`
      ).join('\n\n');

      return {
        type: 'calendar',
        message: `You have ${tomorrowEvents.length} event${tomorrowEvents.length > 1 ? 's' : ''} tomorrow:\n\n${eventList}`,
        events: formattedEvents
      };
    } catch (error) {
      throw error;
    }
  }

  async createEventFromMessage(message) {
    // Simple parsing - in production, you'd use NLP or LLM
    const titleMatch = message.match(/(?:create|schedule|add).*?(?:event|meeting).*?"([^"]+)"/i) ||
                      message.match(/(?:create|schedule|add).*?(?:event|meeting).*?called\s+([^\s]+)/i);
    
    if (!titleMatch) {
      return {
        type: 'calendar',
        message: 'Please specify the event title in quotes, e.g., "Schedule meeting with John"'
      };
    }

    const title = titleMatch[1];

    // Try to extract time
    const timeMatch = message.match(/(?:at|@)\s*(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)/i);
    const dateMatch = message.match(/(?:on|for)\s*(tomorrow|today|monday|tuesday|wednesday|thursday|friday|saturday|sunday)/i);

    let startTime = new Date();
    startTime.setHours(startTime.getHours() + 1); // Default to 1 hour from now
    startTime.setMinutes(0, 0, 0);

    if (dateMatch) {
      const day = dateMatch[1].toLowerCase();
      if (day === 'tomorrow') {
        startTime.setDate(startTime.getDate() + 1);
      } else if (day === 'today') {
        // Keep today
      } else {
        // Handle day of week
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        const targetDay = days.indexOf(day);
        const currentDay = startTime.getDay();
        let daysToAdd = targetDay - currentDay;
        if (daysToAdd <= 0) daysToAdd += 7;
        startTime.setDate(startTime.getDate() + daysToAdd);
      }
    }

    if (timeMatch) {
      const timeStr = timeMatch[1];
      const [hourMin, period] = timeStr.split(/\s+/);
      let [hour, min = '0'] = hourMin.split(':');
      hour = parseInt(hour);
      
      if (period && period.toLowerCase() === 'pm' && hour !== 12) {
        hour += 12;
      } else if (period && period.toLowerCase() === 'am' && hour === 12) {
        hour = 0;
      }
      
      startTime.setHours(hour, parseInt(min), 0, 0);
    }

    const endTime = new Date(startTime);
    endTime.setHours(endTime.getHours() + 1); // Default 1 hour duration

    try {
      const event = await this.calendar.createEvent({
        title: title,
        description: `Created by Rayls.Fi AI Agent`,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString()
      });

      return {
        type: 'calendar',
        message: `✅ Event created: **${title}**\n📅 ${startTime.toLocaleString()}\n🔗 [View in Calendar](${event.htmlLink})`,
        event: this.calendar.formatEvent(event)
      };
    } catch (error) {
      throw error;
    }
  }

  async searchEventsFromMessage(message) {
    // Extract search query
    const queryMatch = message.match(/(?:find|search).*?(?:for|about)\s+"?([^"]+)"?/i);
    
    if (!queryMatch) {
      return {
        type: 'calendar',
        message: 'Please specify what to search for, e.g., "Find events about project review"'
      };
    }

    const query = queryMatch[1];

    try {
      const events = await this.calendar.searchEvents(query, 10);

      if (events.length === 0) {
        return {
          type: 'calendar',
          message: `No events found matching "${query}"`
        };
      }

      const formattedEvents = events.map(e => this.calendar.formatEvent(e));
      const eventList = formattedEvents.map((e, i) => 
        `${i + 1}. **${e.title}**\n   📅 ${e.startFormatted}\n   ${e.location ? `📍 ${e.location}` : ''}`
      ).join('\n\n');

      return {
        type: 'calendar',
        message: `Found ${events.length} event${events.length > 1 ? 's' : ''} matching "${query}":\n\n${eventList}`,
        events: formattedEvents
      };
    } catch (error) {
      throw error;
    }
  }

  async checkAvailability(message) {
    // Simple availability check for today
    try {
      const now = new Date();
      const endOfDay = new Date(now);
      endOfDay.setHours(23, 59, 59, 999);

      const freeBusy = await this.calendar.getFreeBusy(now, endOfDay);
      const busySlots = freeBusy.primary?.busy || [];

      if (busySlots.length === 0) {
        return {
          type: 'calendar',
          message: 'You\'re free for the rest of the day! 🎉'
        };
      }

      const nextBusy = busySlots[0];
      const nextStart = new Date(nextBusy.start);
      const nextEnd = new Date(nextBusy.end);

      if (nextStart > now) {
        const minutesFree = Math.floor((nextStart - now) / 60000);
        return {
          type: 'calendar',
          message: `You're free for the next ${minutesFree} minutes until ${nextStart.toLocaleTimeString()}`
        };
      } else {
        return {
          type: 'calendar',
          message: `You're currently busy until ${nextEnd.toLocaleTimeString()}`
        };
      }
    } catch (error) {
      throw error;
    }
  }

  // Check if a message is calendar-related
  isCalendarCommand(message) {
    const calendarKeywords = [
      'calendar', 'event', 'meeting', 'schedule', 'appointment',
      'today', 'tomorrow', 'next week', 'upcoming',
      'free', 'available', 'busy'
    ];

    const lowerMessage = message.toLowerCase();
    return calendarKeywords.some(keyword => lowerMessage.includes(keyword));
  }
}

// Global instance
window.agentCalendar = new AgentCalendarHandler();

// Initialize on load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => window.agentCalendar.init());
} else {
  window.agentCalendar.init();
}
