# Fix: Firebase "Failed to create Android app"

When `flutterfire configure` fails with **Failed to create Android app**, register the Android app first, then run FlutterFire again.

## Option A: Register via script (Firebase CLI)

From the project root, run:

```bash
./scripts/register_firebase_android.sh
```

Or with a custom project ID:

```bash
./scripts/register_firebase_android.sh food-restaurant-app-1ea6e
```

This creates the Android app with display name **Downtown Chicago** and package `com.app.downtown`. If `firebase.json` exists, it is temporarily moved so the Firebase CLI doesn’t error on the `flutter` property. Then run:

```bash
flutterfire configure --project=food-restaurant-app-1ea6e
```

## Option B: Add the Android app in Firebase Console

1. Open **[Firebase Console](https://console.firebase.google.com)** and select project **food-restaurant-app-1ea6e**.
2. Click the **gear** (Project settings) → **General**.
3. Under **Your apps**, click **Add app** → choose **Android**.
4. Use:
   - **Android package name:** `com.app.downtown`  
     (must match `applicationId` in `android/app/build.gradle.kts`)
   - **App nickname (optional):** e.g. `Downtown Chicago` or leave default.
   - **Debug signing certificate (optional):** can skip for now.
5. Click **Register app**. You can skip downloading `google-services.json`; FlutterFire will generate config.

### After the app is registered (Option A or B)

Run FlutterFire:

```bash
flutterfire configure --project=food-restaurant-app-1ea6e
```

Select the same platforms (e.g. android, ios, macos, web, windows). FlutterFire will detect the existing Android app and generate `lib/firebase_options.dart` without calling the failing create command.

### If it still fails

- Check **Project settings → General → Your apps** for an app with package `com.app.downtown`. If it’s in **Pending deletion**, remove it permanently, then add the app again.
- Run `firebase login --reauth` and accept any terms, then run `flutterfire configure` again.
- Inspect the exact error in **firebase-debug.log** (project root or `~/.config/firebase`).
