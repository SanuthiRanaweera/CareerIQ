# Google Sign-In setup

The Android app uses package ID `com.example.flutter_app`.

The backend and Flutter app must use the same Google Cloud project. The current local project ID is `980818780998`.

In the same Google Cloud project as `GOOGLE_CLIENT_ID` in `backend/.env`, create an **Android OAuth client** with:

- Package name: `com.example.flutter_app`
- SHA-1 for local debug builds: `3E:F1:3B:21:81:F0:3E:8A:7F:F9:41:A9:D0:69:E0:AE:18:93:41:11`

Google Sign-In error code 10 means this Android client is missing or its package/SHA-1 does not match. After creating it, rebuild the app:

```bash
flutter clean
flutter pub get
flutter run
```

For a release build, add the release signing certificate SHA-1 as another Android OAuth client. Keep the Web client ID as `GOOGLE_CLIENT_ID` in `backend/.env`; it is used to verify the ID token on the server.
