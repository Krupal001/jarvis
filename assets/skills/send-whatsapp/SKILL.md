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

Extract exactly two values:

1. contactName
2. message

The contact name comes before the message.

For requests such as:

"send message to Samir hi"

extract:

contactName = "Samir"
message = "hi"

For:

"send Samir on WhatsApp hello how are you"

extract:

contactName = "Samir"
message = "hello how are you"

Do NOT include the message text inside contactName.

Do NOT include words such as "hi", "hello", "hey", or the actual message content in contactName.

The contactName must contain only the person's name.

The message must contain everything intended to be sent.