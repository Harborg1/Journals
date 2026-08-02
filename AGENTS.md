# Repository Guidelines

## Project Structure & Module Organization

This repository contains one Flutter application in `flutter_project/`. Work from that directory for Flutter commands. Application code is in `lib/`: `screens/` contains UI flows, `theme/` holds theme state and definitions, and `security/` contains encryption and session-key helpers. Register bundled assets in `pubspec.yaml` and store them under `assets/` (currently Lottie JSON files). Widget tests live in `test/`. Platform runners are generated projects under `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`; avoid editing generated plugin registrants unless platform work requires it.

## Build, Test, and Development Commands

From `flutter_project/`, use:

```bash
flutter pub get                         # install locked dependencies
flutter run -d chrome                   # run the web app locally
flutter analyze                         # apply flutter_lints static checks
dart format --output=none --set-exit-if-changed lib test
flutter test                            # run widget tests
flutter build web                       # create build/web for Firebase Hosting
```

Use `flutterfire configure` only when the approved Firebase configuration is missing or intentionally changed.

## Coding Style & Naming Conventions

Follow Dart and Flutter conventions enforced by `analysis_options.yaml` and `flutter_lints`: format with `dart format`, use two-space indentation, and keep imports organized by the formatter. Name files `snake_case.dart`, types and widgets `PascalCase`, and methods, variables, and parameters `lowerCamelCase`. Keep screen-specific UI in its screen file; place reusable security or theme logic in the matching `lib/security/` or `lib/theme/` module. Prefer `const` widgets where applicable and avoid unrelated reformatting.

## Testing Guidelines

Use `flutter_test` for widget tests. Name files `*_test.dart` and give tests behavior-focused descriptions, for example `testWidgets('shows validation error for an empty journal entry', ...)`. Add or update tests with each behavior change, especially authentication, encryption, and Firestore interactions. No coverage threshold is configured; run `flutter test` and `flutter analyze` before requesting review.

## Security, Commits, and Pull Requests

Journal data is encrypted and stored through Firebase. Never commit `.env` files, user data, credentials, or newly generated ignored Firebase configuration such as `lib/firebase_options.dart`; coordinate Firebase project or security changes with maintainers.

Use brief, imperative, sentence-case commit subjects such as `Add tree animation asset and update screens` or `Fix login validation`. Keep commits focused; add a body when changing multiple flows, Firebase behavior, or encryption. Pull requests should summarize the change, list validation commands, link related issues when available, include screenshots for UI changes, and call out Firebase/configuration or security impacts.
