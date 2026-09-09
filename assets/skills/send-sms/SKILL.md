---
name: send-sms
description: Send an SMS message to a contact by their name.
---

# Send SMS

## Instructions

Use this skill when the user wants to send an SMS.

Extract:

- contactName
- message

Then call the run_intent tool with:

intent: send_sms

parameters: JSON string containing:

{
  "contactName": "the contact name",
  "message": "the message to send"
}