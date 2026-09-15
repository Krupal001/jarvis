---
name: send-whatsapp
description: Send a WhatsApp message to a contact.
metadata:
  category: messaging
  action: send
---

# Send WhatsApp Message

## Instructions

Use this skill when the user asks to send a WhatsApp message.

Extract exactly two values and return them as JSON with EXACTLY these two
keys — no other keys, no aliases:

```json
{"contactName": "<name>", "message": "<message>"}
```

Do NOT use any other key names such as "to", "recipient", "name", "text",
"body", or "msg". The keys must be exactly "contactName" and "message".

## Extraction rules

- contactName = the person's name only. Never include greeting words like
  "hi", "hello", "hey" in contactName.
- message = everything the user wants sent, including greetings.
- The contact name and message can appear in either order in the user's
  request — look for patterns like "to <name>", "send <name>", or
  "<name>," before the message text.

## Examples

Input: "send message to Samir hi"
Output: {"contactName": "Samir", "message": "hi"}

Input: "send Samir on WhatsApp hello how are you"
Output: {"contactName": "Samir", "message": "hello how are you"}

Input: "send hello to mitul on whatsapp"
Output: {"contactName": "mitul", "message": "hello"}

Input: "whatsapp mitul saying I'll be late"
Output: {"contactName": "mitul", "message": "I'll be late"}

Input: "tell priya i'm on my way"
Output: {"contactName": "priya", "message": "i'm on my way"}

Input: "message john: are we still meeting today?"
Output: {"contactName": "john", "message": "are we still meeting today?"}

Input: "let sarah know the meeting is postponed"
Output: {"contactName": "sarah", "message": "the meeting is postponed"}

## Critical

- Always output valid JSON with exactly the two keys "contactName" and
  "message".
- Never invent a contact name or message that wasn't in the user's request.
- If the message content follows the word "to <name>", the message is
  whatever comes before "to", not after it.