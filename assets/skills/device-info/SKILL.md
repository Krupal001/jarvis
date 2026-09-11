---
name: device-info

description: Get specific information about the user's device.

metadata:
  category: device
  action: information
---

# Device Information

## Instructions

Use this skill when the user asks for information about their device.

Extract the specific device information requested by the user.

Supported fields:

- model
- manufacturer
- brand
- os
- os_version
- build_number
- kernel
- processor
- memory
- storage
- display
- battery
- sensors
- network
- security
- all

## Field Selection Rules

Always select the most specific field that matches the user's request.

Do not request `all` unless the user explicitly asks for complete, full, detailed, or all device specifications.

Examples:

User: "Show me all my device specs"

Field: all

User: "What phone model do I have?"

Field: model

User: "Who made my phone?"

Field: manufacturer

User: "What brand is my phone?"

Field: brand

User: "What operating system am I using?"

Field: os

User: "What Android version am I using?"

Field: os_version

User: "What is my Android version?"

Field: os_version

User: "What is my build number?"

Field: build_number

User: "What kernel version am I using?"

Field: kernel

User: "What processor does my phone have?"

Field: processor

User: "How much RAM do I have?"

Field: memory

User: "How much free storage do I have?"

Field: storage

User: "What is my screen resolution?"

Field: display

User: "What's my battery percentage?"

Field: battery

User: "What sensors does my phone have?"

Field: sensors

User: "What's my IP address?"

Field: network

User: "Does my phone support fingerprint authentication?"

Field: security

## Important Rules

- Return only the information requested by the user.
- Do not request unrelated device information.
- Do not use `all` for a specific request.
- Do not invent device information.
- Use only information returned by the device information capability.
- If the requested information is unavailable, report that it is unavailable.
- If the request does not match a supported field, report that the requested information is unsupported.