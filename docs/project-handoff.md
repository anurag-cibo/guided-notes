# Projektübergabe · 18.09.2026

## Zielthemen und kompakter Zielkopf · 18.09.2026

PR #28 hat Todos, Einstellungen und Zielbilder nach main integriert; Issues #13–19 sind geschlossen. Der Folgeauftrag #29 ergänzt fünf Farbthemen pro Ziel mit sofortiger Vorschau im Editor, Speicherung in Schema 5 und Backupformat 4. Alte Daten und Backups bleiben lesbar. Emoji, Titel und Fortschrittskreis überlappen das Cover; Archivieren und Erreicht-Schalter stehen in einer Zeile, ohne Untertitel. Branch: codex/goal-themes. Der aktuelle Integrationsstatus steht in GitHub.


## Aktueller Abschlussstand · 18.09.2026

Der Nutzer hat die Veröffentlichung und den Abschluss der bisher nur lokalen Arbeit beauftragt. Todos (#13–17), Darstellungswahl (#18), eigene Zielcover (#19) und die nachfolgenden Layoutänderungen werden gemeinsam integriert. Emoji-Kreis und Fortschrittskreis stehen jetzt gleich groß links und rechts neben dem Zieltitel; die Frist steht darunter. Die folgenden Abschnitte dokumentieren historische Zwischenstände; Aussagen zu noch nicht integrierter Arbeit sind anhand des aktuellen GitHub-PR-Status zu lesen.

Abschlussprüfung: alle 32 Unit-/Widgettests und Formatprüfung erfolgreich. Analyse und normaler Android-Debug-Build wurden nach der letzten Codeänderung erfolgreich ausgeführt; die normale APK ist ohne Löschen der App-Daten im Emulator installiert. Native Todo-, Darstellungs- und Bildauswahltests sind in der Validierung dokumentiert. Mehrtägige Nutzung (#4), Streak-Bewertung (#20) und Prüfung des Erklärungsbedarfs (#21) bleiben offen. Sprache, Benachrichtigungen, Erinnerungen und Impressum bleiben ausdrücklich gekennzeichnete Platzhalter.

## Neuer Stand: eigene Cover und Mönchs-Icon · 17.09.2026

Der Nutzer hat eigene Hintergrundbilder ausdrücklich beauftragt (#19). Im Ziel-Editor oben auswählen, ersetzen oder entfernen; das Bild erscheint im Zielkopf. Vorher war nur ein dekoratives Cover vorhanden. Android normalisiert die lokale Kopie auf JPEG bis 1280 Pixel/256 KB, Originaldatei höchstens 20 MB. Schema 4 speichert Bildbytes direkt beim Ziel; Migration aus 1–3 ohne Datenverlust. Backupformat 3 sichert Cover mit, alte Formate 1/2 bleiben lesbar. Die Gesamtgrenze für Backups bleibt 10 MB.

Emoji-Eingabe links neben dem Titel, höchstens ein sichtbares Zeichen einschließlich mehrteiliger Emojis und Flaggen. Der Editor markiert vorhandene Eingabe beim Antippen zum Ersetzen. Das Android-App-Icon zeigt eine meditierende Mönchssilhouette statt des Bergsymbols.

32 Tests, Analyse und native Android-Bildauswahl mit temporärer Testdatenbank erfolgreich. Bild bleibt nach Wiederöffnung erhalten und kann im Editor entfernt werden. Screenshots unter `outputs/cover-editor.png` und `outputs/cover-detail.png`; sie verwenden absichtlich das Referenzbild als synthetische Testdatei. Keine Beispieldaten im normalen Bestand. Eigene Coverauswahl ist damit umgesetzt; ältere Abschnitte mit „Zielbilder offen“ sind überholt.

## Nachtrag: konkrete Layoutwünsche · 17.09.2026

Hell-/Dunkelwahl jetzt in zwei nebeneinanderliegenden Kästen; Systemwahl darunter. Sprache, Benachrichtigungen, Erinnerungen und Impressum sind auf ausdrücklichen Nutzerwunsch als Platzhalter gekennzeichnet. Archiv im Ziele-Tab fest unten über der Navigation. Zielkopf mit flachem dekorativem Cover, Emoji-Kreis neben dem Titel sowie Frist neben dem einzigen Fortschrittskreis; kein zusätzlicher Balken. Cover und Darstellungswahl sind eigene Widgets (`goal_header.dart`, `appearance_selector.dart`). Die frühere Entscheidung gegen Platzhalter ist damit überholt.

## Neuer Arbeitsstand: Einstellungen und Darstellung · 17.09.2026

Auf den Folgeauftrag zur Vervollständigung anhand der Referenz wurden Einstellungen und #18 umgesetzt: Zahnrad in allen drei Tabs, System-/Hell-/Dunkelwahl mit dauerhafter Speicherung, Datensicherung, Dateninformationen, Lizenzen und bestätigtes atomisches Löschen aller Inhalte. Eigene Zielbilder (#19), Streak (#20), Einführung (#21) und mehrtägige Erprobung (#4) bleiben offen. Sprachwahl und Erinnerungen sind wie in #18 festgehalten nicht Teil dieser Umsetzung.

Schema 3 ergänzt lokale Geräteeinstellungen; Migration von 1 und 2 erhält die bestehenden Inhalte. Backupformat bleibt 2 und enthält keine Geräteeinstellungen. Gemeinsame Farben liegen in `lib/theme/guide_theme.dart`; Einstellungen haben eigenes Repository, Controller und Screen. Zielkarten sind kompakter, Zieldetails haben einen Fortschrittsring, Todos zwei zusammenhängende Zeitraumkarten. Ein kleines Bergsymbol ersetzt das Flutter-App-Symbol. Die Gestaltung bleibt ein bearbeitbarer Zwischenstand; eigene Fotos aus der Referenz fehlen weiterhin.

29 Tests und Flutter-Analyse bestanden; Android-Prüfung mit separater temporärer Datenbank für alle fünf Ansichten in beiden Darstellungen und Wiederöffnung erfolgreich. Zehn Screenshots unter `outputs/appearance-{light,dark}-{goals,detail,milestones,todos,settings}.png`; keine Vorschauziele im normalen Datenbestand. Der Screenshot-Test verwendet `flutter drive --keep-app-running`, damit die vorhandene App nicht deinstalliert wird. Details und Grenzen in `docs/validation.md`.

Arbeitsbranch: `codex/settings-and-appearance`, aufbauend auf `feat/todos`; noch nicht nach `main` integriert. Die normale Debug-APK liegt unter `outputs/the-guide-debug.apk`, wurde erfolgreich gebaut und per `adb install -r` im Emulator installiert und gestartet. Issue #18 enthält den Umsetzungsstand und bleibt bis zur Integration offen.

Die folgenden Abschnitte beschreiben frühere Arbeitsstände; neue Einstellungen ersetzen den bisherigen direkten Schild-Zugang zur Datensicherung.

Diese Momentaufnahme hält die bisherige Arbeit und das Nutzerfeedback für weitere Chats fest. Sie ist keine zweite Aufgabenliste; aktueller Status und Akzeptanzkriterien stehen in den [GitHub Issues](https://github.com/anurag-cibo/guided-notes/issues).

## Neuer Arbeitsstand: Todos · 17.09.2026

Auf ausdrücklichen Folgeauftrag wurde auf dem lokalen Branch `feat/todos` der dritte Tab **Todos** mit Tages- und Wochenaufgaben umgesetzt (#13–#17). Noch nicht nach `main` zusammengeführt. Enthalten: Anlegen, tägliches Abhaken/Rückgängig, Wochenziel und Plus/Minus, Bearbeiten für den nächsten Zeitraum, bestätigtes Beenden und eine nur lesbare Historie. Unabhängig von Zielen; lokale Kalendertage, Wochenbeginn Montag, keine erfundenen Stände ausgelassener Zeiträume. Vollständige Regeln in [Produktentscheidungen](product-decisions.md#todos-tages--und-wochenaufgaben).

Schema 2 migriert bestehende Ziele unverändert und speichert Vorlagen getrennt von Zeitraum-Snapshots. Backupformat 2 enthält Todos und Historie; Format 1 bleibt lesbar. Flutter-Analyse ohne Befunde, 25 Tests sowie Android-Todos-Gerätetest bestanden; Debug-APK gebaut und als Update im Emulator gestartet. Der Gerätetest verwendet eine separate temporäre Datenbank und wurde mit `--no-uninstall` ausgeführt. #4 bleibt weiterhin für Nutzererprobung offen. Der folgende Übergabetext beschreibt den vorherigen, bereits integrierten Stand.

## Ergebnis und Rückmeldung

Die ursprünglich als Notiz-App bezeichnete Anwendung ist inzwischen ein Ziele-/Zwischenziele-Prototyp mit dem flexiblen Arbeitsnamen **The Guide**. Der Nutzer wollte zunächst eine startbare Android-App und modularen, leicht erweiterbaren Code. Diese Basis ist vorhanden.

Am 17.09.2026 wurde der zuvor unsichtbare Test-Emulator mit einem sichtbaren Fenster gestartet und die normale App geöffnet. Der Nutzer bestätigt: Die App startet und funktioniert grundsätzlich, ist aber sehr rudimentär und gestalterisch noch nicht hübsch. Das ist eine erste informelle Rückmeldung, keine vollständige Funktionsabnahme oder mehrtägige Nutzererprobung. Konkrete Probleme einzelner Screens, Farben oder Bedienhandlungen wurden noch nicht benannt.

**Fortsetzung am 17.09.2026:** Der Nutzer hat die Bearbeitung der vier P1-Issues und eine grobe Orientierung an der Referenz beauftragt. Die Oberfläche wurde mit warmem Hintergrund, kompakten Karten, Emoji-Flächen, klareren Details und dezenten Statusfarben überarbeitet. Datensicherung ist über das Schild-Symbol erreichbar. Keine Routinen, Bilder oder weiteren P2-Funktionen wurden ergänzt. Die aktuelle Gestaltung braucht noch Nutzerrückmeldung; systematische Beobachtung ohne Anleitung und mehrtägige Erprobung in #4 bleiben offen.

## Bisher umgesetzt

**Abschluss dieses Arbeitsstands:** [PR #26](https://github.com/anurag-cibo/guided-notes/pull/26) wurde nach erfolgreicher CI und abgeschlossenem Review per Squash nach `main` zusammengeführt (Commit `0c9352c`). Die Issues #9, #11 und #12 sind geschlossen. Der Nutzer bestätigt ausdrücklich, dass #4 für Rückmeldung und mehrtägige Erprobung offen bleiben soll. Es ist keine weitere Umsetzung aus diesem Chat ausstehend.

Über [PR #24](https://github.com/anurag-cibo/guided-notes/pull/24) nach erfolgreicher Build-CI auf `main` zusammengeführt; Merge-Commit `8c1eac1`. Damit wurden die Issues #1, #2, #3, #5, #6, #7, #8 und #10 geschlossen.

- Flutter-Android-Projekt, festgelegte SDK-Version, deutsche Lokalisierung und GitHub Actions mit Debug-APK-Artefakt.
- Produktkern, drei synthetische Beispiele, erste Nutzungsstrecke, Status-/Fortschritts-/Zeitregeln und reduzierter Screenflow dokumentiert.
- Ziele anlegen und bearbeiten, Motivation, optionales Emoji und optionale Frist; höchstens fünf nicht archivierte Ziele.
- Zwischenziele nach Ziel gruppiert, mit Status und Fortschritt; direkte Eintragssprünge und Cluster-Auswahl für lange Listen.
- Details sowie Archivieren, Wiederherstellen und bestätigtes endgültiges Löschen vorhanden. Für #9 und #11 wurden gezielte Widget- und Persistenzprüfungen ergänzt. Fristen bleiben auch bei erreichten Zielen als Datum sichtbar; Zielerfolg wird separat angezeigt.
- Export/Import (#12): versioniertes JSON inklusive Archiv; echte Android-Dateiauswahl, Vorschau und Bestätigung. Import nur in leere App, keine Überschreibung oder Zusammenführung. Ungültige Dateien und Teilfehler erhalten den bestehenden Datenbestand. Maximal 10 MB; Datei unverschlüsselt. Rundlauf über den Android-Dateidialog und erneute Datenbanköffnung geprüft.
- Offline-Speicherung mit Drift/SQLite, Fremdschlüsseln, Transaktionen und zusätzlicher Absicherung der Fünf-Ziele-Grenze in der Datenbank.
- Subagenten dürfen laut AGENTS.md eingesetzt werden, wenn die Gesamtkosten einschließlich Koordination und Prüfung sinken, ohne Qualität einzubüßen. Bisher wurde ohne Subagenten gearbeitet.

## Festgelegte Grundlagen

Fünf **aktive**, nicht fünf insgesamt gespeicherte Ziele. Erreichte Ziele zählen bis zum ausdrücklichen Archivieren mit. Zielfortschritt ist das gleichgewichtete Mittel der Zwischenziele; die bewusste Zielerfolg-Markierung bleibt davon getrennt. Erreichen archiviert nicht automatisch. Fristen sind optionale Kalenderdaten, keine zweite Fortschrittsanzeige. Motivation genügt zunächst als Freitext; kein eigener Notizbereich.

Details: [Produktentscheidungen](product-decisions.md). Speicherung, Backupformat und künftige Schemaänderungen: [Speicherstrategie](storage.md). Routinen, Bilder, Streaks, Hell-/Dunkelwahl, Cloud und Accounts sind nicht Teil der aktuellen Umsetzung. Backups regelmäßig außerhalb des Geräts aufbewahren. Nutzererprobung und weitere Vereinfachung bleiben in #4.

## Technischer Einstieg

Flutter **3.47.4**, Dart **3.13.3**, JDK 21. SDK lokal unter dem ignorierten `work/flutter`; keine globale Flutter-PATH-Einrichtung nötig. Der Wrapper `tool/flutter.ps1` nutzt das lokale SDK, `FLUTTER_ROOT` oder Flutter im PATH.

```powershell
.\tool\flutter.ps1 devices
.\tool\flutter.ps1 run -d emulator-5554
```

Der vorhandene AVD heißt `Medium_Phone_API_36.0` (Android 16 / API 36, x86_64). Bei der Übergabe war die App im sichtbaren Emulator geöffnet; in späteren Chats den tatsächlichen Gerätestatus erneut prüfen. Paket/Activity: `de.anurag.guided_notes/.MainActivity`. Wenn der Emulator nicht läuft, über den Device Manager in Android Studio öffnen. App-Daten erhalten; zum normalen Testen nicht deinstallieren oder den Emulator zurücksetzen.

Zum Abschluss wurde die aktuelle normale APK einschließlich der Review-Korrektur erneut mit `adb install -r` installiert und gestartet; vorhandene Nutzerdaten blieben erhalten. Erkennbar ist die neue Oberfläche an „Schön, dass du da bist.“ und dem Schild-Symbol für Datensicherung. Das Flutter-App-Symbol blieb unverändert. Die synthetischen Vorschauziele sind nicht Teil der normalen App. Der Nutzer hatte zuletzt „Neues Ziel“ geöffnet; laufende Eingaben bei der nächsten Arbeit respektieren. Die kurzzeitig gesetzte Emulator-Testoption `always_finish_activities` wurde auf ihren vorherigen, nicht gesetzten Zustand zurückgesetzt.

Der normale auslieferbare Debug-Build liegt lokal unter `outputs/the-guide-debug.apk`. Screenshots des synthetischen Teststands und des leeren Starts liegen unter `outputs/android-goals.png` und `outputs/android-empty.png`. `outputs/` und das SDK sind absichtlich nicht in Git enthalten; auf einem anderen Rechner APK neu bauen oder das CI-Artefakt verwenden. Die Integrationstests können die APK im Build-Verzeichnis durch einen Test-Einstieg ersetzen; für normales Ausprobieren `flutter run` oder erneut `flutter build apk --debug` verwenden.

Aktuelle UI-Vorschau mit synthetischen Daten: `outputs/ui-goals.png`, `outputs/ui-detail.png`, `outputs/ui-milestones.png` und `outputs/ui-backup.png`. Die älteren `android-*.png` zeigen den Stand vor der Überarbeitung.

Architektur: `domain` für Modelle und Fachregeln, `data` für Datenbank und Repository, `application` für den Controller, `presentation` für Screens und Formulare. Theme und App-Einstieg in `lib/app.dart`. Flutter-Navigator und ChangeNotifier; kein zusätzliches State-/Routing-Paket. Gestaltung lässt sich überwiegend in `presentation` und `app.dart` ändern, ohne die Datenstruktur anzufassen.

## Bereits nachgewiesene Qualität

17 Fachregel-, Persistenz-, Backup-, Fehler- und Widgettests bestanden. Android-Debug-Build erfolgreich. Die zwei Phasen des Android-Kernablauftests wurden nach der UI-Änderung erneut erfolgreich ausgeführt; zusätzlich der native Backup-Rundlauf. Der frühere Offline-Nachweis bleibt in der Validierung dokumentiert; beim aktuellen Neustarttest war der Flugmodus aus. Große Schrift und ein Sprung zum 80. Zwischenziel wurden ebenfalls geprüft.

Die abschließende [CI für PR #26](https://github.com/anurag-cibo/guided-notes/actions/runs/35159852006) ist grün. Der einzige Review-Befund (wartender Dateiaufruf bei Activity-Ende) wurde in `e6d756c` behoben und vom Review als erledigt bestätigt. Der gesonderte Gerätetest einer erzwungenen Activity-Neuerzeugung bleibt eine dokumentierte Testgrenze, kein behaupteter Nachweis.

Der Test-Runner deinstalliert die App standardmäßig am Ende: Für die zweiphasige Persistenzprüfung ist `--no-uninstall` nötig. Tests nur mit Testdaten ausführen; sie erzeugen und entfernen ihr synthetisches Ziel. Vollständige Befehle und Grenzen des Nachweises: [README](../README.md) und [Validierung](validation.md).
