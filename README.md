# Flutter background service

Flutter application that runs foreground and background services and displays notifications as well as logging events. The key components are:

## Background Service (BackgroundService class):
Uses the `flutter_background_service` package to run background tasks on both Android and iOS.<br />
- It initializes the service with AndroidConfiguration for Android and IosConfiguration for iOS. The service operates in the foreground on Android, showing notifications, and in the background on iOS.
- It logs background task executions using shared preferences.
- Periodic tasks run every 1 second and log the current date and device information (model) to shared preferences. Another task logs "Running background task" every 2 seconds.
- Notifications are handled through a separate NotificationService class (detailed below).

## Notification Service (NotificationService class):
Uses `flutter_local_notifications` to display notifications. It supports both Android and iOS.<br />
- It ensures required permissions for notifications are requested and creates an Android notification channel for displaying notifications.
- Notifications are shown when the service runs, displaying the current date.

## Main Application :
- Initializes the BackgroundService and NotificationService.
- Displays a simple UI that shows the service's status (device info and current date), as well as buttons to toggle between foreground and background modes or stop/start the service.
- Users can also clear data stored in shared preferences.

## Logging (LogView class):
Displays logs (background task executions) stored in shared preferences. A Timer checks for new logs every second and updates the UI.
Key Components:
`_onStart`: This is the main background task entry point for both iOS and Android. It sets up listeners for foreground/background mode switching, stops the service, and runs periodic tasks that log background activities.
`_onIosBackground`: This handles background tasks on iOS by reloading preferences and logging tasks.

Notifications: Managed using the NotificationService class, which triggers notifications for background tasks.

## UI:
- Displays device information and current date.
- Provides buttons to control service modes and stop/start the service.
- Logs background task activity.

