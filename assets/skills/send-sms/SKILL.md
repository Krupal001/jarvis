---
name: send-sms
description: Send an SMS message to a contact.
metadata:
  category: communication
  action: send
---

# Send SMS

## Instructions

Use this skill when the user asks to send an SMS message.

Extract exactly two values:

- `contactName`: only the recipient's name.
- `message`: the complete message to send.

The recipient name comes before the message.

Example:

User: "send SMS to Samir hi"

contactName: "Samir"

message: "hi"

User: "send SMS to Rahul how are you"

contactName: "Rahul"

message: "how are you"

Never include the message content in `contactName`.