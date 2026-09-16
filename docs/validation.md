# Validierung

Stand: 16.09.2026. Lokal: Windows 11, Flutter 3.47.4 (Release-Tag 9584c6713b), Dart 3.13.3, JDK 21 aus Android Studio. Android-Testgerät: vorhandener Emulator „Medium_Phone_API_36.0“, Android 16 / API 36, x86_64.

## Automatisierte Prüfungen

- Formatierung: `dart format --output=none --set-exit-if-changed lib test integration_test`.
- Statische Analyse: `flutter analyze lib test integration_test`.
- Fachregeln, reale SQLite-Dateien, Schreib-/Ladefehler und Widgetabläufe: `flutter test`.
- Android-Build: `flutter build apk --debug`.
- Android-Ablauf und Datenprüfung nach Prozessneustart: die zwei dokumentierten Aufrufe von `integration_test/app_test.dart`.

Die konkreten Endergebnisse des Builds und Gerätetests werden nach Abschluss hier ergänzt. Keine mehrtägige Nutzererprobung behauptet; diese gehört zu #4. Export/Import (#12) bleibt vor wichtigen eigenen Daten offen.

## Einrichtungshinweise

Das SDK ist lokal unter dem ignorierten `work/flutter` installiert. Der Release-Tag wird bewusst festgehalten; `flutter doctor` meldet deshalb gegebenenfalls einen unbekannten Branch und einen fehlenden globalen PATH-Eintrag. Der PowerShell-Wrapper funktioniert ohne globale PATH-Änderung. Fehlendes Visual Studio betrifft nur Windows-Desktop, nicht das Android-Projekt.
