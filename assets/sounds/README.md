# Sound Assets

Place your notification sound file here as `order_notification.mp3`.

For now, the app will use a fallback method if the file is not found.

To add a custom ringtone:
1. Add your sound file as `order_notification.mp3` in this directory
2. Update `pubspec.yaml` to include the asset:
   ```yaml
   flutter:
     assets:
       - assets/sounds/
   ```
