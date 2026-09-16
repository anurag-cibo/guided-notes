# Validierung

## Todos-Erweiterung · 17.09.2026

- `flutter analyze --no-pub lib test integration_test`: keine Befunde.
- `flutter test --no-pub`: 25 Tests bestanden. Neu: reale Schema-1-Migration und Datei-Neustart, Tages-/Wochenwechsel, Sommerzeit-/Jahresgrenzen, Uhr-Rückstellung, ausgelassene Zeiträume, historische Vorlagenwerte, Beenden, Zählergrenzen, Backupformat 2/Legacy-Import und Import-Rollback sowie Bedienung mit großer Schrift.
- `flutter test integration_test/todos_test.dart -d emulator-5554 --no-uninstall --no-pub`: bestanden. Tagesaufgabe anlegen/abhaken, Wochenaufgabe anlegen/zählen, vollständiges Schließen und Wiederöffnen der temporären SQLite-Datei, Rückgängig. Separate temporäre Datenbank; reale App-Inhalte bleiben unberührt. Dies prüft Datenbank-Neustart im Testprozess, keinen vollständigen Prozessneustart.
- `flutter build apk --debug --no-pub`: erfolgreich. Danach normale APK unter `outputs/the-guide-debug.apk` gesichert und per `adb install -r` installiert; kein Test-Einstieg in der ausgelieferten APK.
- Neuer Backupinhalt ist über Codec-/Repositorytests abgedeckt; der Android-System-Dateidialog wurde für diese Änderung nicht erneut durchlaufen. Zeitzonenwechsel sind durch Kalenderschlüsselregeln abgedeckt, nicht durch Umstellen der Emulator-Zeitzone getestet.

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
- Der GitHub-Workflow prüft Formatierung, Analyse, Tests und Android-Build und stellt die Debug-APK als Artefakt bereit. Die zugehörigen Läufe und ihr Status sind in [PR #24](https://github.com/anurag-cibo/guided-notes/pull/24/checks) verlinkt. Der lokale Prüfnachweis oben ergänzt diese CI um die tatsächlichen Android-Gerätetests.

Beim ersten Versuch der zweiphasigen Prüfung entfernte Flutter die Test-App nach Phase 1 automatisch. Ursache anhand der Flutter-CLI und des fehlenden Android-Pakets geklärt; beide Phasen mit `--no-uninstall` erfolgreich wiederholt. Das ist in der README reproduzierbar dokumentiert.

Keine mehrtägige Nutzererprobung behauptet; diese gehört zu #4. Der ursprüngliche Stand ohne Export/Import ist durch die folgende Prüfung ergänzt.

## Ergänzung · Kernablauf, Gestaltung und Backup · 17.09.2026

- Abschließende [GitHub-CI](https://github.com/anurag-cibo/guided-notes/actions/runs/35159852006) einschließlich Formatierung, Analyse, 17 Tests und Android-Build bestanden. Review-Korrektur bestätigt; [PR #26](https://github.com/anurag-cibo/guided-notes/pull/26) als `0c9352c` zusammengeführt. #9, #11 und #12 geschlossen; #4 bleibt auf ausdrücklichen Nutzerwunsch offen.
- Formatprüfung (22 Dart-Dateien), statische Analyse und `git diff --check`: bestanden. Normaler Android-Debug-Build erfolgreich.
- Ziele, Details, Zwischenziele und Datensicherung mit synthetischen Beispielen im Emulator visuell geprüft. Lokale Screenshots: `outputs/ui-goals.png`, `outputs/ui-detail.png`, `outputs/ui-milestones.png`, `outputs/ui-backup.png`. Dabei doppelte Leerzustandsangaben und die wenig hilfreiche Anzeige `0/0` entfernt. Die Vorschau verwendet nur eine In-Memory-Datenbank. Dies ist keine Nutzerbeobachtung ohne Anleitung und kein mehrtägiger Nutzungstest.
- `flutter test`: **17 Tests bestanden**. Neu sind Backup-Rundlauf auf echter SQLite-Datei mit erneutem Öffnen, alle Statuswerte, Unicode und Fristen, inkompatible/fehlerhafte Dateien, Schutz bestehender Daten und erzwungener Rollback mitten im Import. Archivieren, Wiederherstellen und Löschen werden zusätzlich nach Datei-Neuöffnung geprüft.
- Widgettests prüfen Motivation bearbeiten, überfällige und fehlende Fristen, getrennten Zielerfolg, Archivfilter, Löschbestätigung samt Abbruch, Importvorschau samt Abbruch/Bestätigung und Export. Bestehende Tests für doppelte Schriftgröße und lange Listen bestehen weiterhin.
- Android-Kernablauf und anschließender Prozessneustart: beide Phasen erneut bestanden. Der Flugmodus war bei dieser Wiederholung aus; der ältere Offline-Nachweis bleibt oben dokumentiert.
- `integration_test/backup_test.dart`: echter Android-Export über `ACTION_CREATE_DOCUMENT`, Auswahl derselben Datei über `ACTION_OPEN_DOCUMENT`, bytegleicher Inhalt und Import in eine separate leere Testdatenbank; erneute Öffnung und vollständiger Vergleich bestanden. Der Test berührt nicht die echte `guide.sqlite` und entfernt seine temporären Datenbanken.
- Die Drift-Debugwarnung zu mehreren Datenbanken tritt in den Backup-Tests auf, weil Quelle und Ziel gleichzeitig geöffnet werden. Sie verwenden ausdrücklich verschiedene Dateien bzw. getrennte In-Memory-Verbindungen, keinen gemeinsamen Executor.
- Review-Nachbesserung: Beim Zerstören der Android-Activity wird ein noch wartender Dateiaufruf explizit abgebrochen. Späte Ergebnisse eines I/O-Threads werden danach ignoriert, damit derselbe Aufruf nicht doppelt beantwortet wird. Android-Build erneut bestanden; erzwungene Activity-Neuerzeugung während Dateiauswahl wurde nicht separat im Gerätetest nachgewiesen.

Der native Dateidialogtest benötigt eine Person oder Geräteautomation für **Speichern** und die anschließende Auswahl der erzeugten Datei:

```powershell
.\tool\flutter.ps1 test integration_test/backup_test.dart -d emulator-5554 --no-uninstall
```

Er verwendet synthetische Daten. Die exportierte Testdatei bleibt am gewählten Speicherort. Nach Integrationstests wieder die normale App mit `lib/main.dart` bauen/installieren, damit kein Test-Einstieg ausgeliefert wird.

## Erste Nutzerrückmeldung · 17.09.2026

App im sichtbaren Android-Emulator gestartet. Der Nutzer bestätigt Start und grundsätzliche Funktion, bewertet die Oberfläche aber als sehr rudimentär und gestalterisch noch nicht zufriedenstellend. Dies ersetzt keine systematische oder mehrtägige Erprobung. Kontext und Einstieg für weitere Chats: [Projektübergabe](project-handoff.md).

## Einrichtungshinweise

Das SDK ist lokal unter dem ignorierten `work/flutter` installiert. Der Release-Tag wird bewusst festgehalten; `flutter doctor` meldet deshalb gegebenenfalls einen unbekannten Branch und einen fehlenden globalen PATH-Eintrag. Der PowerShell-Wrapper funktioniert ohne globale PATH-Änderung. Fehlendes Visual Studio betrifft nur Windows-Desktop, nicht das Android-Projekt.
