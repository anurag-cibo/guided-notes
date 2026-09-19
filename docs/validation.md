# Validierung

## Kurzer Emoji-Impuls und Überschriften-Navigation · 19.09.2026

Neuester Nutzerwunsch ersetzt die zeitgesteuerte Fade-Markierung: Emoji-Hintergrund blinkt 180 ms ohne Fade auf und verschwindet direkt. Die gesamte Leiste behält ihren 320-ms-Fade beim Scrollen. Zielüberschriften im Zwischenziele-Tab öffnen Zieldetails. Dort wechselt die Überschrift Zwischenziele zum bestehenden Haupttab und fokussiert die passende Zielgruppe; keine gestapelten Detailseiten. Plus-Buttons bleiben getrennt bedienbar. Archivierte Ziele sind weiterhin nicht im aktiven Zwischenziele-Tab enthalten.

72 Tests und Analyse erfolgreich; native Android-Prüfung heading_navigation_test.dart bestätigt Wechsel, korrekten Haupttab und Zielgruppe. Unabhängiges Screenshotreview mit gpt-5.6-luna: 8/10, keine auffälligen Layout-/Kontrastprobleme. Screenshots outputs/navigation-focused-group.png, navigation-goal-detail.png und navigation-after-flash.png. Speicherung/Schema unverändert. Normales Emulator-Update mit vorheriger Sicherung; kein zusätzliches Release.


## Sortieren, Zielwechsel und Animationen · 19.09.2026

- Finale Formatierung und Analyse ohne Befunde; 71 Unit-/Widgettests bestanden.
- Reale Schema-10-Datei nach Schema 11 migriert; sämtliche Inhalte erhalten. Reihenfolge nach Datei-Neustart und Backup-Rundlauf identisch. Todo-Gutschriften und Rücknahme nach Wechsel des Zwischenziels erhalten; ungültige/archivierte Zielpositionen ändern keine Daten.
- Gesten: Ziele vor/nach einem Ziel, Zwischenziele in Zieldetails, Wechsel zu anderer/leerem Ziel, Abbruch, Autoscroll mit stillstehendem Finger und Timer-Rebuild während eines Drags geprüft. Zeitgesteuertes Aufheben und Zurücksetzen der Emoji-Markierung sowie teiltransparenter Zwischenzustand der ganzen Leiste geprüft.
- Native Android-Prüfung integration_test/reorder_motion_test.dart im separaten Testpaket erfolgreich: Ziehen in allen drei Ansichten, Zielwechsel, leere Gruppe, Emoji- und Leistenanimation. Debug-Build der normalen App erfolgreich, ausschließlich per adb install -r aktualisiert. Vor Installation Sicherung outputs/before-reorder.tar; bestehende Daten nach echter Migration im normalen App-Prozess spalten-/zeilenweise unverändert, Fremdschlüssel intakt.
- Kurze Demo-Aufnahme outputs/ziele-ziehen-und-animationen.mp4. Unabhängiges Review mit gpt-5.6-luna: 7,5/10 anhand zeitmarkierter Frames. Nachgebessert: keine durchscheinenden Texte und kein seitliches Abschneiden der gezogenen Karte. Reviewer konnte die MP4 nicht direkt abspielen; die genaue Animationsdauer ist durch Widgettests, nicht durch dessen visuelles Urteil belegt. Einfügelinie kann von der darübergezogenen Karte teilweise verdeckt werden.


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

## Todo-Scrollrad und kompakte Liste · 19.09.2026

54 Unit-/Widgettests bestanden. Scrollgesten, Speichern und Wiederöffnung des Beitrags, Fortschrittsbuchung und Rücknahme sowie Grenzen 1/100 bei doppelter Schriftgröße in Hell/Dunkel geprüft. Statische Analyse ohne Befunde; Formatprüfung und git diff --check erfolgreich. Isolierter Android-Darstellungs-/Neustarttest bestanden; Scrollrad und kompakte grüne Beitragsanzeige in beiden Darstellungen anhand der Screenshots geprüft. Keine Änderung an Schema oder Berechnung.

## Kompakte Todo-Zeiträume · 19.09.2026

Datum ohne Wochentag und Jahr neben der Zeitraumüberschrift, kleiner gesetzt. Wochen mit gleichem Monat kürzen den wiederholten Monat (z. B. 14.–20.9.). Bei großer Schrift darf die Kopfzeile umbrechen; der Plus-Button bleibt erreichbar. Wochenaufgaben zeigen einen Fortschrittsbalken zwischen Minus/Plus mit der Anzahl darüber. Bestehende Widgettests prüfen Datumsposition, Balkenwerte beim Erledigen/Rückgängigmachen und große Schrift. 54 Unit-/Widgettests und Analyse erfolgreich. Version 0.2.2+4; keine Änderungen an Speicherung oder Berechnung.

## Stabile Fortschrittsaktualisierung · 19.09.2026

Der Schreibschutz im GoalsController bleibt bestehen, erzeugt aber keinen eigenen UI-Zwischenstand mehr. Vorher wurden alle Checkboxen/Plus-Aktionen für jeden Klick kurz deaktiviert und der Bildschirm zweimal benachrichtigt. Jetzt wird einmal der bestätigte Stand veröffentlicht. Formulare behalten ihren eigenen Speicherzustand.

Todo-Zähler verwenden eine gezielte Aktualisierung innerhalb derselben Transaktion: betroffener Zeitraum, dessen Beiträge und betroffene Zwischenziele. Zielbilder, Themes, Vorlagen und andere Zeiträume werden nicht erneut aus SQLite geladen. Undo berücksichtigt den früher zugeordneten Beitrag. Snapshot-Zugriffe auf Ziele, Zwischenziele und Todo-Vorlagen sind per ID indiziert. Volles Laden bleibt für Start, Zeitraumwechsel und strukturelle Änderungen bestehen; Historie ist weiterhin vollständig im Snapshot (keine Paginierung).

56 Unit-/Widgettests und Analyse erfolgreich. Neue Nachweise: nur eine Benachrichtigung pro Mutation; fremde Checkboxen/Plus bei künstlich verzögertem Speichern unverändert aktiv; kein Voll-Reload beim Zählerklick; statische Objekte bleiben identisch; Ergebnis entspricht vollständigem Datenbankstand nach Deckelung, Zuordnungswechsel und Undo; Fehler rollen Daten und Snapshot zurück. Keine pauschale FPS-Aussage oder Hardware-Benchmark abgeleitet.

## Feine Fortschrittsbeiträge · 19.09.2026

60 Unit-/Widgettests erfolgreich. Neu geprüft: exakte Addition und Rücknahme von 0,1 %, 100-%-Deckelung, Wochenbonus nur auf letzter Wiederholung, Wechsel des Modus mit erhaltenem Undo, Backup-Rundlauf, ungültige Modi, Schema-8-Fixture mit bestehenden Beiträgen und Bildbytes, Dateineustart, FK-Integrität und erhaltene ID-Zähler. Beide Räder wechseln ihre Nachkommastufen, halten Grenzen und funktionieren bei großer Schrift. Bestehende Migrationstests aus Schema 1–7 bleiben erfolgreich. Der durchschnittliche Zielfortschritt wird jetzt auf zwei Nachkommastellen gerundet statt auf ganze Prozent.

Android-Abschlussprüfung: Beide Räder und Editor in Hell/Dunkel visuell geprüft. Wochenmodus im Editor geändert und bestätigt: erste zwei Wiederholungen ohne Beitrag, dritte mit 2,5 %, Rücknahme zieht den Beitrag ab. Dateineustart erhält den Stand. Normale App vor dem Update unter outputs/before-fine-progress.tar gesichert; nach Migration alle früheren Zeilen/Spalten verglichen: vollständig erhalten, Prozentfelder exakt um Faktor 100 skaliert, alte Modi perCompletion, FK-Prüfung ohne Befund. Nachher-Sicherung unter outputs/after-fine-progress.tar. Signierte APK auf separatem AVD über frühere Version installiert und bestehendes Testziel nach Neustart gefunden. Normale Emulator-App wieder geöffnet. Externes Review: Dokumentation um Migrationen aus Schema 1–8 ergänzt; Bindestrich im Datum entspricht dem ausdrücklichen Nutzerbeispiel 14.9-20.9.

## Zwischenziel-Todos und einheitliche Prozentwahl · 19.09.2026

61 Unit-/Widgettests und Analyse erfolgreich. Der neue Editor-Test prüft Filterung nach Zwischenziel, tägliche und wöchentliche Zähler, sofortige Vorauswahl bei Neuanlage, Speichern eines manuellen Fortschritts vor Todo-Aktionen, korrekte Beiträge/Rücknahme, späteres Speichern ohne Überschreiben und Layout bei 320 px mit doppelter Schriftgröße. Der Prozentpicker erhält die Nachkommastelle beim Wechsel der Ganzzahl (auch 99,25 %) und begrenzt auf 100 %. Der bestehende Todo-Ablauf verwendet jetzt 8,5 % einschließlich Speicherung und Undo.

Android-Test mit separatem Paket erneut erfolgreich: neue Zwischenziel-Ansicht in Hell/Dunkel aufgenommen, Wochen-Todo dort erhöht/zurückgenommen, weitere Todo-Flows und Datenbank-Neustart geprüft. Zweiter visueller Reviewer bewertet die neuen Screenshots mit 8/10 in beiden Modi; keine notwendige Korrektur. Vorherige Bewertung der Radbreiten: 8/10 hell, 7,5/10 dunkel. Screenshots unter outputs/appearance-{light,dark}-milestone-{editor,todos}.png. Testbilder im Emulator unter Downloads/The-Guide-Testbilder.
## Zielkarten, direkte Bearbeitung und sofortiges Entfernen · 19.09.2026

Version 0.3.2+8 bündelt #44–46 und das kreisrunde Mönchslogo beim Android-Start. Zielkarten verwenden das vorhandene Bild im oberen Kartenbereich, mit kontraststützendem Verlauf. Prozentzahl und Balken liegen darunter. Zwischenziele öffnen aus den Zieldetails direkt ihren Editor.

Nutzerentscheidung zu #46: Historie und bereits gebuchte Beiträge bleiben erhalten. Inaktive Vorlagen verschwinden sofort aus beiden aktuellen Ansichten, erlauben keine weiteren Buchungen und erzeugen keine neuen Zeiträume. Keine Schema- oder Backupformatänderung.

Neue Regressionstests prüfen Navigation bei mehreren Zielen, Speichern/Abbrechen, Entfernen über den Zwischenziel-Editor mit Aktualisierung beider Ansichten, tägliche/wöchentliche Aufgaben mit unterschiedlichen Erledigungsständen und Beiträgen sowie Datei-Neustart und nächsten Zeitraum. Cover-Test prüft Bild oberhalb des Balkens, Entfernen/Ersetzen und langen Titel bei 320 px und doppelter Schrift.

Android-Darstellungs-/Neustarttest mit separat geprüftem Paket de.anurag.guided_notes.integration erfolgreich. Aktuelle Screenshots outputs/appearance-{light,dark}-goals.png unabhängig bewertet: jeweils 8/10. Sie zeigen ein kontrastreiches synthetisches Bild bei normaler Schrift; sehr helle Fotos und große Schrift sind damit nicht separat visuell belegt. Große Schrift ist durch den Widgettest abgedeckt.

Abschlussprüfung: alle 64 Unit-/Widgettests erfolgreich, statische Analyse ohne Befunde, Format und git diff --check erfolgreich. Debug- und signierter universeller Release-Build erfolgreich; apksigner bestätigt die gültige Signatur mit dem bisherigen Zertifikat. Normale Emulator-App ausschließlich per adb install -r aktualisiert. Datenbank vor/nach Installation bytegleich (SHA256 0c325c7a782cbd4db77eab7e87a667391941d91ee8d5ebc0e81452a2d998c708); lokale Sicherung outputs/before-compact-release.tar. Kreisrundes Logo beim tatsächlichen Android-Start unter outputs/round-start-logo.png geprüft. Keine erneute Release-Geräteinstallation auf separatem AVD in diesem Durchlauf; Emulatornachweis mit Debug-Build.

Review-Nachtrag: Screenreader-Prozentwert entfernt wie die sichtbare Anzeige unnötige Nachkommastellen. Flutter 3.47 verlangt für die progressBar-Rolle jedoch einen maschinenlesbaren Dezimalpunkt; die direkte Übernahme des deutschen Kommas wurde von CI erkannt und korrigiert. Ein Test mit 35,25 % und aktivierter Semantik sichert diesen Unterschied ab. Der Entfernungstest bestätigt zusätzlich, dass ein anderes aktives Todo in beiden Ansichten erhalten bleibt. Beide betroffenen Testdateien (6 Tests) erneut erfolgreich. Das Startlogo wurde unabhängig mit 9/10 bewertet; Screenshot belegt den hellen Android-Start.

## Emoji-Zielsprünge und schaltbare Karten-Cover · 19.09.2026

68 Unit-/Widgettests und Analyse erfolgreich, Format und git diff --check ohne Befund. Neue Tests decken fünf Ziele bei 320 px und doppelter Schrift, identische Emojis mit eindeutigen Ziel-IDs, horizontale Balken-/Prozentanordnung sowie Cover-An/Aus für Standardmotiv und eigenes Bild ab. Editor und Detailcover behalten Bilddaten; Einstellung bleibt bei anderen Änderungen, Dateineustart und Backup erhalten. Echte Schema-9-Fixture erhält sämtliche exportierten Inhalte einschließlich gebuchter Hundertstel-Beiträge; kein zweites Skalieren. Alte Migrationen und Backups bleiben geprüft.

Isolierter Android-Darstellungs-/Neustarttest erfolgreich; Screenshots unter outputs/appearance-{light,dark}-{goals,milestones,editor}.png. Zweiter Reviewer: Ziele 8/10, Zwischenziele 8,5/10, Editor 7,5/10 in beiden Modi. Screenshots zeigen eigenes grafisches Bild, Standardmotiv und ausgeschaltetes Karten-Cover; große Schrift und fünf Emojis sind zusätzlich durch Widgettests abgedeckt. Kleine Einschränkungen: Zahlbreite verändert die Balkenlänge leicht; der kleine Editor-Schalter erklärt seinen Zweck per Tooltip/Screenreader.

Normaler Debug-Build 0.3.3+9 per adb install -r aktualisiert, keine Deinstallation. Sicherung outputs/before-emoji-covers.tar. Nach abgeschlossenem App-Start vor/nach Migration sämtliche bisherigen Tabellen, Zeilen und Spalten verglichen: unverändert; Schema 10, neue Cover-Schalter aktiviert, Fremdschlüsselprüfung ohne Befund. Der erste Snapshot wurde vor Abschluss des Starts genommen; der erneute Vergleich bestätigt die vollständige Migration. Keine Testdaten im normalen Datenbestand.

Nachfolgende Nutzerwünsche: Restzeit direkt unter dem Zwischenziel-Status innerhalb des Covers, unten ausschließlich Fortschrittsbalken und Prozent. Die Emoji-Markierung blendet bei echtem Benutzerscrollen aus; Sprunganker bleibt erhalten, erneutes Antippen markiert wieder. Alle 68 Tests und Analyse erneut erfolgreich, einschließlich Markierung vor/nach Scrollen/erneutem Tippen. Android-Darstellungs-/Neustarttest wiederholt erfolgreich. Zweitreview der aktuellen Zielkarten und des Zustands nach freiem Scrollen: jeweils 8,5/10 in beiden Modi. Statische Screenshots belegen den Endzustand, keine Bewertung der Animation. Letztes normales Emulator-Update per adb install -r mit bytegleicher Datenbank, Sicherung outputs/before-emoji-scroll-update.tar.

## Eigene Messskalen, Einheiten und verpflichtendes Warum · 19.09.2026

80 Unit-/Widgettests und statische Analyse erfolgreich. Neue Tests prüfen auf-/absteigende Skalen, Dezimalwerte, eigene/leere Einheiten, Pflicht-Warum, Wertebereich und Rundung ohne vorzeitiges Erreichen. Todo-Beiträge über 100, Zieldeckelung, Wochenbonus, exakte Rücknahme nach Bereichsänderung/Zielwechsel und Backup-Rundlauf sind abgedeckt. Echte Schema-11-Dateimigration erhält alte Prozentwerte, Todo-Historie, Beiträge, IDs und ID-Zähler; frühere Migrationstests bleiben erfolgreich. Bestehende Zwischenziele brauchen erst beim nächsten Speichern ein Warum.

Widgettests prüfen Bücher 0–12, Beitrag +1, Pflichtfeldfehler und freien/entfernten Einheitentext bei 320 px und doppelter Schrift. Ein vorhandener Beitrag über 100 bleibt auch nach Wechsel auf eine Standardskala bearbeitbar. Native Android-Prüfung mit isoliertem Paket de.anurag.guided_notes.integration erfolgreich: Hell/Dunkel, 100 → 80 kg, Beitrag −0,5 kg und Rücknahme, Datenbank-Neustart und Backup. Screenshots outputs/metrics-{light,dark}-{overview,editor-top,editor-values,todo-contribution}.png. Unabhängiges Review mit gpt-5.6-luna: 8/10; kleinere Schwäche ist die Länge des Editors und der erklärenden Todo-Hinweise. Keine blockierenden Layoutprobleme.

Normaler Debug-Build 0.3.3+9 erfolgreich; Update ausschließlich per adb install -r. Vorherige Sicherung outputs/before-metrics.tar, Datenbank während Installation bytegleich (SHA256 9f1d52c0f84ab181f86cba8136b0b3dead68f9324667c8c4c069e90545b573ed). Nach App-Start sämtliche vorherigen Tabellen, Zeilen und Spalten unverändert; neue Skalen entsprechen 0–100 %, aktueller Messwert dem bisherigen Fortschritt, historische Messwert-Beiträge den bisherigen Prozentbeiträgen. Schema 12 und Fremdschlüssel geprüft. Normale App geöffnet, keine Testdaten eingebracht. Backupformat 11 liest weiterhin Versionen 1–10.
