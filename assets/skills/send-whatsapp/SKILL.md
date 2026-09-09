---
name: send-whatsapp
description: Send a WhatsApp message to a contact by their name.
---

# Send WhatsApp

## Instructions

Use this skill when the user wants to send a WhatsApp message.

Extract:

- contactName
- message

Then call the run_intent tool with:

intent: send_whatsapp

parameters: JSON string containing:

{
  "contactName": "the contact name",
  "message": "the message to send"
}
