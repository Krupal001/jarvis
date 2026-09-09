---
name: install-app
description: Install an Android application requested by the user.
metadata:
  category: device
  action: install
---

# Install App

## Instructions

Use this skill when the user asks to install an Android application.

Extract the application name from the user's request.

Call the install-app capability with the application name.

Do not invent or guess the Android package name.
The application name will be resolved through the Play Store search service.