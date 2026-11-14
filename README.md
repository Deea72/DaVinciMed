# CromerCare (Flutter)
Login -> consent + photo -> 3 questions -> probability of a 3rd-degree burn.
Works on Android, iOS and Chrome (`flutter run -d chrome`).

Setup: copy `pubspec.yaml` and `lib/` into your Flutter project, run `flutter pub get`.
iOS: add NSCameraUsageDescription and NSPhotoLibraryUsageDescription to Info.plist.

- Login is a DEMO (any valid email + password of 6+ chars). Replace `submit()` in
  `AuthScreen` with real auth (Firebase Auth / Supabase).
- AI model: set `classifier` at the top of `lib/main.dart` to `HttpBurnClassifier(url)`.
- Question weights: `lib/questions.dart` (placeholder, needs clinical review).
