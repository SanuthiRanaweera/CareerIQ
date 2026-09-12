# CareerIQ Flutter App

## Run on an Android phone

1. Install Flutter and Android Studio. In Android Studio, install the Android SDK, SDK Platform-Tools, and an Android SDK platform.
2. Add the Flutter SDK `bin` directory and `%LOCALAPPDATA%\Android\Sdk\platform-tools` to the Windows PATH.
3. Run `flutter doctor` and follow any remaining Android setup instructions.
4. On the phone, enable Developer options and USB debugging, connect it by USB, and accept the debugging prompt.
5. From this directory, run:

```powershell
flutter pub get
flutter devices
flutter run
```

To select a specific phone, use `flutter run -d <device-id>`. Keep the terminal open for hot reload; press `r` after changing Dart code.

## Run from VS Code

Open `frontend/flutter_app` as the VS Code folder, select the connected phone in the device picker, and press `F5`.

## Backend access from a physical phone

Do not use `localhost` in the Flutter API URL for a physical phone. Use the development computer's LAN IPv4 address instead, make the backend listen on the LAN interface, and ensure Windows Firewall allows the backend port. The phone and computer must be on the same Wi-Fi network.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
