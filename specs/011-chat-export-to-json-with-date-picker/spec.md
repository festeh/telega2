# Feature Specification: Chat Export to JSON

**Feature Branch**: `011-chat-export-to-json-with-date-picker`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "Add chat export feature - save as JSON to downloads folder - offer a from-to date picker before saving"

## User Scenarios

### User Story 1 - Export Chat Messages (Priority: P1)

As a user viewing a chat, I want to export messages as a JSON file to my Downloads folder, so I can back up or process conversation history outside of the app.

**Acceptance Scenarios**:

1. **Given** I am in a chat, **When** I tap "Export chat" from the app bar menu, **Then** a date range picker appears
2. **Given** the date range picker is shown, **When** I select a from-date and to-date, **Then** I can confirm to start the export
3. **Given** I confirm the export, **When** messages are fetched and serialized, **Then** a JSON file is saved to my Downloads folder
4. **Given** the export completes, **When** the file is saved, **Then** I see a confirmation with the file name

### User Story 2 - Date Range Selection (Priority: P1)

As a user, I want to pick a date range before exporting so I can export only the messages I need instead of the entire chat history.

**Acceptance Scenarios**:

1. **Given** the date picker opens, **When** displayed, **Then** it defaults to the last 30 days (or chat creation date if newer)
2. **Given** I pick dates, **When** the from-date is after the to-date, **Then** the picker prevents confirmation
3. **Given** I pick dates, **When** I tap "Export", **Then** only messages within that range are included in the JSON

## JSON Format

```json
{
  "chat": {
    "id": 12345,
    "title": "Chat Name",
    "type": "private"
  },
  "exportDate": "2026-03-29T12:00:00Z",
  "dateRange": {
    "from": "2026-03-01T00:00:00Z",
    "to": "2026-03-29T23:59:59Z"
  },
  "messageCount": 42,
  "messages": [
    {
      "id": 1,
      "date": "2026-03-15T10:30:00Z",
      "senderId": 67890,
      "senderName": "John",
      "isOutgoing": false,
      "type": "text",
      "content": "Hello!",
      "replyToMessageId": null,
      "forwardedFrom": null,
      "reactions": []
    }
  ]
}
```
