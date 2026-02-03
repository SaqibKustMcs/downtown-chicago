# Firebase Setup Instructions

## Prerequisites
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app to your Firebase project
3. Download the `google-services.json` file

## Steps to Configure Firebase

### 1. Download google-services.json
1. Go to Firebase Console → Project Settings
2. Under "Your apps", select your Android app (or add a new one)
3. Package name: `com.app.food_flow_app`
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### 2. Replace the Template File
The file `android/app/google-services.json` currently contains a template. Replace it with the actual file downloaded from Firebase Console.

### 3. Verify Build Configuration
The following files have been configured:
- ✅ `android/settings.gradle.kts` - Google Services plugin added
- ✅ `android/build.gradle.kts` - Buildscript with Google Services classpath
- ✅ `android/app/build.gradle.kts` - Plugin applied and Firebase dependencies added
- ✅ `pubspec.yaml` - Firebase Flutter packages added

### 4. Firebase Services Enabled
The app is configured to use:
- **Firebase Analytics** - App analytics
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Database
- **Firebase Storage** - File storage
- **Firebase Messaging** - Push notifications

### 5. Build the App
After adding the `google-services.json` file, run:
```bash
flutter clean
flutter pub get
flutter run
```

## Important Notes
- The `google-services.json` file is required for the app to build successfully
- Never commit the actual `google-services.json` to version control if it contains sensitive data
- The template file will cause build errors until replaced with the actual Firebase configuration
