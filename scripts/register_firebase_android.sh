#!/usr/bin/env bash
# Register the Android app with Firebase so "flutterfire configure" can use it
# instead of failing on apps:create. Run from project root:
#   ./scripts/register_firebase_android.sh

set -e
PROJECT_ID="${1:-food-restaurant-app-1ea6e}"
PACKAGE_NAME="com.app.downtown"
DISPLAY_NAME="Downtown Chicago"

cd "$(dirname "$0")/.."

# If firebase.json exists and has a "flutter" key, Firebase CLI can throw
# "unknown property: flutter" and may affect the create call. Temporarily move it.
FIREBASE_JSON="firebase.json"
BACKUP_JSON=""
if [ -f "$FIREBASE_JSON" ]; then
  BACKUP_JSON="${FIREBASE_JSON}.bak.$$"
  mv "$FIREBASE_JSON" "$BACKUP_JSON"
  echo "Temporarily moved $FIREBASE_JSON to $BACKUP_JSON"
fi

echo "Registering Android app: $DISPLAY_NAME ($PACKAGE_NAME) in project $PROJECT_ID"
if firebase apps:create android "$DISPLAY_NAME" --package-name="$PACKAGE_NAME" --project="$PROJECT_ID"; then
  echo "Android app registered. You can now run: flutterfire configure --project=$PROJECT_ID"
else
  echo "Registration failed. Try adding the app manually in Firebase Console:"
  echo "  https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
  echo "  Add app → Android → Package name: $PACKAGE_NAME"
fi

if [ -n "$BACKUP_JSON" ] && [ -f "$BACKUP_JSON" ]; then
  mv "$BACKUP_JSON" "$FIREBASE_JSON"
  echo "Restored $FIREBASE_JSON"
fi
