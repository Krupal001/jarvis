---
name: device-info
description: Get information about the user's device.
metadata:
  category: device
  action: information
---

# Device Information

## Instructions

Use this skill when the user asks for information about their device.

Extract what information the user is requesting.

Supported categories:

- device
- system
- processor
- memory
- storage
- display
- battery
- sensors
- network
- security

If the user asks for all device specifications, request all available device information.

If the user asks for a specific category, request only that category.

Examples:

User: "Show me all my device specs"
Category: all

User: "How much RAM do I have?"
Category: memory

User: "How much free storage do I have?"
Category: storage

User: "What processor does my phone have?"
Category: processor

User: "What's my battery percentage?"
Category: battery

Do not invent device information.
Use only information returned by the device information capability.