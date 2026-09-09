---
name: uninstall-app
description: Uninstall an app from the device
metadata:
  category: device
  action: uninstall
---

## Instructions

Use this skill when the user asks to uninstall an Android application.

Extract the application name from the user's request.

Call the uninstall-app capability with the application name.

Do not invent or guess the Android package name.
only extract the application name from the user's request. not the json array.