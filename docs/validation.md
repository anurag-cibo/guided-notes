# Validierung

Stand: 16.09.2026. Lokal: Windows 11, Flutter 3.47.4 (Release-Tag 9584c6713b), Dart 3.13.3, JDK 21 aus Android Studio. Android-Testgerät: vorhandener Emulator „Medium_Phone_API_36.0“, Android 16 / API 36, x86_64.

## Automatisierte Prüfungen

- Formatierung: `dart format --output=none --set-exit-if-changed lib test integration_test`.
- Statische Analyse: `flutter analyze lib test integration_test`.
- Fachregeln, reale SQLite-Dateien, Schreib-/Ladefehler und Widgetabläufe: `flutter test`.
- Android-Build: `flutter build apk --debug`.
- Android-Ablauf und Datenprüfung nach Prozessneustart: die zwei dokumentierten Aufrufe von `integration_test/app_test.dart`.

## Ergebnisse

- Formatprüfung: bestanden, 18 Dart-Dateien unverändert formatiert.
- Analyse: bestanden, keine Befunde in App, Tests und Integrationstest.
- `flutter test`: **11 Tests bestanden**. Enthalten sind Fortschritts-/Status-/Datumsregeln, SQLite-Neuöffnung einer echten Datei, schnelle parallele Anlageversuche, Wiederherstellung an der Grenze, Trigger, Fremdschlüssel, Transaktionsrollback, kaskadierendes Löschen, Lade-/Schreibfehler, erste Nutzungsstrecke, Android-Zurück-Semantik, doppelte Schriftgröße und direkter Sprung zum 80. Zwischenziel samt Clusterwechsel.
- Android-Debug-Build: bestanden. Auslieferungsdatei lokal: `outputs/the-guide-debug.apk` (normaler Einstieg `lib/main.dart`, kein Test-Einstieg).
- Android-Integration Phase 1: bestanden. Über die echte Oberfläche Ziel und Motivation angelegt, Zwischenziel erstellt und erreicht, 100 % Gesamtfortschritt geprüft, zum Zwischenziel und zurück navigiert.
- Anschließend normalen App-Build mit `adb install -r` installiert, Prozess mit `am force-stop` beendet und `MainActivity` neu gestartet. Das synthetische Ziel mit 100 % Fortschritt war im normalen App-Build sichtbar; Screenshot lokal unter `outputs/android-goals.png`. Flugmodus war eingeschaltet (`airplane_mode_on = 1`).
- Android-Integration Phase 2: bestanden. Nach weiterem vollständigem Prozessstopp vorhandene Motivation, Status und berechneten Fortschritt verglichen. Anschließend ausschließlich das eigene synthetische Testziel samt Kinddaten entfernt.
- CI-Workflow ist eingerichtet, aber **noch nicht auf GitHub ausgeführt**: Der Push wurde von der automatischen Freigabeprüfung abgelehnt. Es wurden keine Remote-Issues als erledigt geschlossen.

Beim ersten Versuch der zweiphasigen Prüfung entfernte Flutter die Test-App nach Phase 1 automatisch. Ursache anhand der Flutter-CLI und des fehlenden Android-Pakets geklärt; beide Phasen mit `--no-uninstall` erfolgreich wiederholt. Das ist in der README reproduzierbar dokumentiert.

Keine mehrtägige Nutzererprobung behauptet; diese gehört zu #4. Export/Import (#12) bleibt vor wichtigen eigenen Daten offen.

## Einrichtungshinweise

Das SDK ist lokal unter dem ignorierten `work/flutter` installiert. Der Release-Tag wird bewusst festgehalten; `flutter doctor` meldet deshalb gegebenenfalls einen unbekannten Branch und einen fehlenden globalen PATH-Eintrag. Der PowerShell-Wrapper funktioniert ohne globale PATH-Änderung. Fehlendes Visual Studio betrifft nur Windows-Desktop, nicht das Android-Projekt.
