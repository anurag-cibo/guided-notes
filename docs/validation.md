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

## Einstellungen und beide Darstellungen · 17.09.2026

- 29 Unit-/Widgettests erfolgreich. Neue Tests prüfen Migration 2 → 3 und Datei-Neustart, unbekannte Darstellungswerte, Schreibfehler ohne falsche Erfolgsauswahl, Lösch-Rollback, anschließenden Backup-Import und Themewechsel einschließlich Systemmodus. Bestehende Migration-1-Tests prüfen nun den vollständigen Weg bis Schema 3.
- Einstellungen bei 390 × 844 logischen Pixeln und doppelter Schriftgröße geprüft, einschließlich Abbruch und Bestätigung des Gesamtlöschens. Bestehende große-Schrift-Tests für Ziele und Todos bleiben grün.
- Flutter-Analyse ohne Befunde. Android-Test `appearance_test.dart` auf API 36 erfolgreich: separate temporäre Datenbank, Ziele/Details/Zwischenziele/Todos/Einstellungen in Hell und Dunkel, Darstellungswahl und Daten nach vollständigem Datenbank-Schließen/Wiederöffnen erhalten.
- Zehn Screenshots erzeugt und visuell geprüft. Testbedingte Tap-Markierungen können kurzzeitig sichtbar sein. Kein Nachweis formaler WCAG-Konformität oder mehrtägiger Nutzung.

```powershell
.\tool\flutter.ps1 drive --driver integration_test/screenshot_driver.dart --target integration_test/appearance_test.dart -d emulator-5554 --keep-app-running
# Danach immer wieder den normalen App-Einstieg bauen:
.\tool\flutter.ps1 build apk --debug
```

`--keep-app-running` verhindert die standardmäßige Deinstallation durch `flutter drive`. Der Test verwendet ausschließlich seine temporäre Datenbank. Screenshots landen lokal in `outputs/appearance-*.png`. Der neue Gesamtlöschvorgang wurde nur gegen synthetische Testdaten geprüft, nie gegen den regulären App-Datenbestand. Native Dateidialoge wurden in diesem Schritt nicht erneut geprüft; der bestehende Backup-Widgettest bleibt erfolgreich.

### Layoutanpassung nach Nutzerfeedback

Die geänderten Ansichten mit zwei Darstellungskästen, markierten Einstellungs-Platzhaltern, festem Archiv und kompaktem Cover-Kopf wurden erneut im Android-Screenshot-Test geprüft. 29 Tests, Analyse und normaler Debug-Build erfolgreich. Die Widgetprüfungen verwenden jetzt den einzelnen Prozentwert im Ring; die Sichtbarkeit der Erreicht-Aktion wird vor dem Antippen explizit hergestellt.

## Zielbilder, Emoji-Feld und Icon · 17.09.2026

32 Tests bestanden; darunter echte Migration 3 → 4, Bildbytes nach Datenbank-Neustart, Backup-Rundlauf mit Bild, Bildentfernung und endgültiges Löschen. Ungültige Bilddaten und mehrere Emoji-Zeichen werden ohne Änderung am bestehenden Ziel abgelehnt. Ein Widgettest prüft Bildauswahl-Abbruch, Auswahl, ein einzelnes sowie zusammengesetztes Emoji und Speichern. Analyse ohne Befunde.

Android-Gerätetest `integration_test/cover_image_test.dart` erfolgreich: Android-Dateiauswahl geöffnet, die eigens bereitgestellte Referenzbildkopie gewählt, normalisierte Bildkopie gespeichert, Ziel und Emoji nach Wiederöffnung geprüft und Cover über den Editor entfernt. Separater temporärer Datenbestand; die normale App-Datenbank wurde nicht verwendet. Screenshots: `outputs/cover-editor.png`, `outputs/cover-detail.png`. Der Test benötigt eine Auswahl im nativen Dialog. Bilder von 20 MB, sämtliche EXIF-Orientierungen und Activity-Neuerzeugung wurden nicht separat als Gerätetest durchgespielt.

```powershell
.\tool\flutter.ps1 drive --driver integration_test/screenshot_driver.dart --target integration_test/cover_image_test.dart -d emulator-5554 --keep-app-running
.\tool\flutter.ps1 build apk --debug
```
## Zielthemen und kompakte Details · 18.09.2026

34 Unit-/Widgettests erfolgreich; anschließend zusätzlicher Test für 320 Pixel Breite und doppelte Schriftgröße in Hell und Dunkel bestanden (insgesamt nun 35 Tests). Die neuen Prüfungen decken Migration 4 → 5 mit erhaltenen Inhalten, Farbe nach vollständigem Datei-Neustart, Archiv und Backup-Rundlauf, Import der Formate 1–3 mit Standardfarbe sowie Ablehnung unbekannter Farbwerte ab. Widgetprüfung: Auswahl und Wiederöffnung im Editor, tatsächliche Überlappung des Titels mit dem Cover und gemeinsame Zeile für Archivieren/Erreicht. Analyse ohne Befunde.

Android-Darstellungstest mit separater temporärer Datenbank erfolgreich: verschiedenfarbige Zielkarten sowie Details, Aktionszeile und Editor in Hell und Dunkel. Wiederöffnung erhält die Farbwerte. Screenshots unter outputs/appearance-{light,dark}-{goals,detail,actions,editor}.png visuell geprüft. Die anfängliche Screenshot-Testblockade wurde durch einen fehlenden Pump nach dem Scrollen verursacht und im Test behoben. Reguläre App-Daten bleiben unverändert; anschließend wird wieder die normale APK gebaut und per Update installiert.
## Kompakte Aktionen, eigene Themes und isolierte Android-Tests · 18.09.2026

38 Unit-/Widgettests erfolgreich, Analyse ohne Befunde. Neue Prüfungen: Migration 5 → 6, Erhaltung bestehender Ziele/Farben, vier Theme-Rollen, Bearbeitung gemeinsam verwendeter Themes, Datei-Neustart, Backup inklusive Referenzen, ungültige Farben/IDs sowie vollständiger Rollback bei fehlgeschlagenem Zielimport nach bereits eingefügten Themes. Alte Formate 1–4 bleiben lesbar. UI-Test erstellt aus einem ungespeicherten Ziel ein eigenes Theme, wählt eine Hex-Farbe, übernimmt es und bearbeitet es über Einstellungen. Layouttest bestätigt feststehende Zielaktionen/Todo-Historie beim Scrollen.

Android-Darstellungstest in Hell/Dunkel mit eigenen Themes erfolgreich; Ziele, Details, Zwischenziele, Todos, Einstellungen, Theme-Liste und Theme-Editor visuell geprüft. Die normale x86_64-APK wurde mit --target-platform android-x64 ohne ABI-Split gebaut und gestartet.

**Vorfall und Behebung:** Der erste Drive-Lauf traf auf die alte ABI-Split-Version 4001. Flutter deinstallierte die normale App automatisch beim Downgrade auf Version 1; ihre bisherige Datenbank ging verloren. Die einzige gefundene Sicherung enthielt alte synthetische Testdaten und wurde nicht als Nutzerbestand wiederhergestellt. Der Nutzer wurde informiert. --keep-app-running schützt nur vor Deinstallation am Testende.

Danach wurden Android-Test-Entrypoints unter integration_test in Gradle technisch auf de.anurag.guided_notes.integration getrennt (App-Name „The Guide · Test“). Normale und Test-APK wurden gebaut und ihre unterschiedlichen Paketkennungen mit aapt vor Installation geprüft. Der erneute Drive-Test mit der geprüften Test-APK bestand. SHA-256 der neu angelegten normalen guide.sqlite war vor/nach diesem isolierten Test identisch; beide Pakete existieren parallel. Anschließend wurde die normale App geöffnet. Dieser Nachweis stellt den zuvor verlorenen Bestand nicht wieder her.

Empfohlener Emulator-Ablauf: Test-APK mit explizitem --target integration_test/appearance_test.dart und --target-platform android-x64 bauen, Paketkennung vor Installation prüfen und flutter drive --use-application-binary mit dieser APK verwenden. Kein --split-per-abi für Emulator-Updates. Ältere Testbefehle und Datenerhalt-Aussagen in diesem Dokument sind historische Nachweise und ersetzen die neue Pakettrennung nicht.

## Zeitkreis und Theme-Verwaltung · 18.09.2026

- 45 Unit-/Widgettests bestanden, einschließlich Zeitberechnung, Schema-6-Migration/Neustart/Backup, Theme-Löschung mit Rollback, Archiv-Scrollverhalten, begrenzter Theme-Auswahl und getrennter Fortschrittsanzeige. Analyse ohne Befunde, Format und git diff --check erfolgreich.
- Normaler Android-x64-Debug-Build sowie expliziter appearance_test-Build erfolgreich. Test-Paketkennung vor Installation mit aapt als de.anurag.guided_notes.integration geprüft. Android-Darstellungs-/Neustarttest in Hell und Dunkel bestanden; Screenshots von Zielkopf, Übersicht, Editor und Themes visuell geprüft.
- Normale App während des Gerätetests gestoppt; Datenbank-Prüfsumme davor/danach identisch. Normale APK mit adb install -r aktualisiert und erneut gestartet. Vorherige und migrierte Datenbanken per SQLite verglichen: sämtliche bisherigen Spalten/Zeilen in goals, milestones, goal_themes, todo_templates, todo_entries und app_settings unverändert. Schema 7, alle fünf vorhandenen Demoziele besitzen das neue Startdatum. Lokale Sicherungen bleiben unter outputs/ und werden nicht committed.

## Todo-Verknüpfung · 19.09.2026

53 Unit-/Widgettests und statische Analyse erfolgreich. Gezielt geprüft: Beiträge pro Wiederholung, 100-%-Begrenzung, Rücknahme nach Zuordnungswechsel, reine Zuordnung ohne Tracking, Tageswechsel/Uhr-Rückstellung, Archivierung/Löschen, manuelle Fortschrittsänderungen, atomarer Rollback bei Buchen/Rücknahme/Import, Migration aus Schema 7, Dateineustart und Backup-Rundlauf. Historie scrollt ans Inhaltsende, Zielauswahl blendet abhängig von der Scrollrichtung aus/ein; bestehende Tests für direkte Sprünge bleiben grün.

Isolierter Android-Darstellungs-/Neustarttest bestanden, einschließlich verknüpfter Wochenaufgabe mit +5/-5 Prozentpunkten in Hell und Dunkel. Editor und Auswahl anhand der Screenshots visuell geprüft. Die normale Datenbank blieb während des Gerätetests per SHA-256 unverändert. Normale APK 0.2.0+2 als Update installiert; anschließend alle bisherigen Datenbankwerte gegen die Sicherung verglichen: unverändert erhalten, Schema 8 und keine rückwirkenden Beiträge. Tageswechsel darf ausschließlich neue Todo-Zeiträume ergänzen. App anschließend wieder geöffnet.

Release-Prüfung: Universelle signierte APK 0.2.0+2 gebaut (Android ab API 24, ARM64/ARMv7/x86_64). Signatur mit apksigner verifiziert. Auf einem separaten leeren AVD installiert, synthetisches Ziel angelegt und nach Prozessneustart wiedergefunden. Test-AVD danach beendet, normale App weiterhin geöffnet. Der private Release-Schlüssel und key.properties bleiben ignoriert.

Review-Korrektur: Release-Schlüsselprüfung hängt direkt an Signier-/Packaging-Tasks. Gradle-Dry-Run bestätigt: lintRelease benötigt keine privaten Schlüssel; auch der Einstieg über assemble enthält die Schlüsselprüfung. Ausführung des Prüftasks mit fehlender sowie unvollständiger Konfiguration schlägt erwartungsgemäß fehl. Vollständige private Konfiguration anschließend wiederhergestellt. Flutter-Builds und Flutter-Tests nicht parallel ausführen: Beide können den generierten Android-Plugin-Registrant verändern.
