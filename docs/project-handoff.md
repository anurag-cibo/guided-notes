# Projektübergabe · 19.09.2026

## Emoji-Leiste und Karten-Cover · 19.09.2026

Folgeauftrag #48 umgesetzt: einzeilige Emoji-Zielsprünge im Zwischenziele-Tab, Prozentzahl rechts neben dem Zielbalken, Standardmotiv auf Zielkarten ohne eigenes Bild. Die Restzeit steht direkt unter dem Zwischenziel-Status im Cover. Freies Scrollen lässt die Emoji-Markierung ausfaden, ohne den Sprunganker zu verändern; erneutes Antippen markiert wieder das gewählte Ziel. Rechts neben der Bildauswahl/Papierkorb im Ziel-Editor steuert ein kleiner Schalter ausschließlich das Karten-Cover. Foto und Detailcover bleiben erhalten. Schema 10/Backup 9 speichern showCardCover; ältere Daten erhalten true. Die Migration aus Schema 9 skaliert Fortschritte nicht erneut.

68 Tests, Analyse und Android-Darstellungs-/Neustarttest erfolgreich. Visuelles Review: Karten 8/10, Emoji-Leiste 8,5/10, Editor 7,5/10 in Hell/Dunkel. Emulator enthält den Debug-Stand 0.3.3+9. Bestehende Daten vor/nach Migration vollständig verglichen und unverändert erhalten; Sicherung outputs/before-emoji-covers.tar. Arbeitsbranch codex/emoji-navigation-card-covers; Integration anhand GitHub prüfen. Für diesen Folgeauftrag wurde kein neues Release veröffentlicht.


## Kompaktes Release 0.3.2 · 19.09.2026

Issues #44–46 umgesetzt: Zielcover auf Karten, direkter Zwischenziel-Editor aus Zieldetails und sofortiges Entfernen von Todos aus beiden aktuellen Ansichten. Nutzerbestätigt bleiben Historie und bereits gutgeschriebene Beiträge erhalten. Mönchslogo beim Start kreisrund. Schema 9 und Backupformat 8 unverändert. Version 0.3.2+8, vorhandener Release-Schlüssel weiterverwendet.

64 Tests, Analyse, isolierter Android-Darstellungs-/Neustarttest sowie Debug-/Release-Build erfolgreich. Zweiter visueller Reviewer: Zielkarten 8/10 in Hell und Dunkel. Großschrift/320 px durch Widgettest geprüft. Validierungsdetails in docs/validation.md.

Normale App in emulator-5554 per Update geöffnet, Datenbank dabei bytegleich. Sicherung outputs/before-compact-release.tar erhalten. Keine Testdaten in den normalen Bestand geschrieben. APK outputs/the-guide-0.3.2.apk, zugehörige SHA256-Datei outputs/the-guide-0.3.2.apk.sha256.

Beauftragt sind Integration, GitHub-Release und Löschen des Arbeitsbranches codex/goal-covers-todo-removal nach Abschluss. Den aktuellen Integrations-/Veröffentlichungsstatus anhand GitHub prüfen; ältere Abschlussstände darunter sind historisch. #4, #20 und #21 bleiben außerhalb dieses Auftrags.


## Verbindlicher Abschlussstand dieses Chats · 19.09.2026

PR [#42](https://github.com/anurag-cibo/guided-notes/pull/42) ist nach erfolgreichem GitHub-Build und externem CodeRabbit-Review per Squash integriert: `2f42ea3ab8b928723a48f72752b2c2638a548e43`. Issue #43 ist geschlossen. Der identische Dateistand des Arbeitsbranches `codex/compact-fraction-wheel` wurde gegen main geprüft; der erledigte Branch kann lokal und auf GitHub entfernt werden. Ältere Abschnitte unten dokumentieren historische Zwischenstände, keine aktuell ausstehende Integration.

Veröffentlicht: [Android-Testversion 0.3.1](https://github.com/anurag-cibo/guided-notes/releases/tag/v0.3.1), App-Version `0.3.1+7`. APK `the-guide-0.3.1.apk`, SHA256 `786499665433acac0d883436cf433f7456b51a5a88f2c6b35fe0a10be781d53a`. Der vorhandene private Release-Schlüssel wurde weiterverwendet. Schlüssel, `android/key.properties`, lokale Sicherungen und Emulator-Daten bei Aufräumarbeiten unbedingt erhalten.

Enthalten sind die einheitlichen Nachkommastufen mit schmalerem rechtem Rad und der Zwischenziel-Editor mit Status/Frist nebeneinander sowie gemeinsam implementierten täglichen/wöchentlichen Todo-Karten. Todo-Aktionen speichern offene Zwischenziel-Änderungen vorab und halten den Fortschritt synchron. Neue Todos dort sind mit dem Zwischenziel und 2,5 % vorbelegt. Bei 100 % ist nur Nachkommastelle 0 erlaubt. Details stehen in README und den späteren Abschnitten unten.

Prüfungen: Analyse ohne Befunde, 61 Unit-/Widgettests, nativer Android-Test in Hell/Dunkel einschließlich Beiträgen, Rücknahme und Dateineustart sowie Debug-/Release-Build erfolgreich. Zweiter visueller Reviewer: Zwischenziel-Ansicht 8/10 in beiden Modi. Der einzige externe Review-Hinweis zur expliziten Dokumentation der 100-%-Grenze wurde behoben; abschließendes Review und CI erfolgreich. Für künftige optische Änderungen gilt die Nutzerpräferenz aus AGENTS.md: unabhängige Screenshot-Bewertung, mindestens 6,5/10 anstreben.

Die normale App ist auf emulator-5554 aktualisiert und geöffnet; keine Nutzerdaten ersetzt. Sicherung unmittelbar vor dem endgültigen Update: `outputs/before-milestone-todos.tar`. Datenbank-Prüfsumme vor/nach Installation identisch: `07eec52b544a7f4ba43177e34d9ebdf5e04644f56bfa92dc1ebbf9225a977b06`. Gerätetests ausschließlich mit Paket `de.anurag.guided_notes.integration`; normale Updates nur per `adb install -r`, bei Fehler abbrechen und niemals automatisch deinstallieren.

Drei Testmotive (hell, dunkel, Hochformat) liegen im Emulator unter **Downloads/The-Guide-Testbilder**, außerdem lokal unter `outputs/testbilder`. Sie sind in Androids Medienübersicht registriert und über „Hintergrundbild auswählen“ zugänglich. Emulator und Testbilder bleiben für den Nutzer verfügbar.

Zum Abschluss neu in GitHub vorgefunden und weiterhin offen: #44 Zielcover auf Zielkarten, #45 Zwischenziel aus Zieldetails bearbeiten, #46 beendete/gelöschte Todos sofort aus aktuellen Ansichten entfernen. Außerdem bleiben #4 Nutzererprobung, #20 Streak-Bewertung und #21 Erklärungsbedarf offen. Diese Folgethemen wurden in diesem Abschluss nicht umgesetzt; verbindlicher aktueller Aufgabenstand bleibt GitHub. Der Nutzer hat Dokumentation, Branch-Aufräumen und Archivierung dieses Chats beauftragt.

## Kompaktere Todos · 19.09.2026

PR #36 ist integriert; APK 0.2.0 veröffentlicht. Der anschließende UI-Wunsch ersetzt die Prozentpunkte-Texteingabe durch ein begrenztes Scrollrad (1–100). Die Todo-Liste zeigt nur einen grünen Beitrag neben dem Titel; Zuordnung und Hinweise bleiben im Editor, Hinweise jetzt als Stichpunkte. Speicherung und Berechnung bleiben unverändert. Version 0.2.1+3 verwendet denselben privaten Release-Schlüssel. Aktuelle Emulator-Daten vor dem Update unter `outputs/before-todo-wheel.tar` gesichert; niemals durch Testdaten ersetzen.

## Todo-Verknüpfung und Handy-APK · #35

PR #34 ist auf main integriert. Folgeauftrag #35 ergänzt optionale Todo-Zuordnung, gesondertes Fortschritts-Tracking und 1–100 Prozentpunkte pro Erledigung. Nutzerbestätigt: jede Wochen-Wiederholung zählt, Rücknahme zieht den tatsächlichen Beitrag ab. Schema 8, Backupformat 7; Einzelbeiträge sichern Undo auch nach Wechsel, 100-%-Deckelung und Neustart. Todo-Editor und suchbare Zwischenzielauswahl sind eigene Dateien, Beitragsbuchung liegt in `todo_progress.dart`. Todo-Historie scrollt mit, Zielauswahl blendet je Scrollrichtung aus/ein. Aktueller Integrationsstatus: GitHub #35.

Version 0.2.0+2 bereitet eine universelle Handy-APK vor. Dauerhaften Release-Schlüssel unter `work/release-signing/` und die ignorierte `android/key.properties` unbedingt erhalten und privat sichern; nicht veröffentlichen. Emulator weiter mit Debug-Signatur aktualisieren, Gerätetests mit separatem Paket. Vor dem Update wurde der aktuelle normale Datenbestand unter `outputs/before-todo-links.tar` gesichert. Keine Demodaten ersetzen oder zurücksetzen.

## Zeitkreis und Theme-Verwaltung · 18.09.2026

PR #32 ist integriert. Folgeauftrag #33 entfernt den Appnamen aus der Begrüßungszeile, lässt das Archiv am Ende der Zielliste mitscrollen und verkleinert Plus-Ringe ohne gefüllten Hintergrund. Im Zielkopf ersetzt ein Zeitkreis den Fortschrittskreis; Fortschritt steht als Balken darunter. Schema 7/Backupformat 6 ergänzen ein dauerhaftes Startdatum. Ältere Ziele starten bei der ersten Verwendung dieser Version. Themes sind unter „Themes“ verwaltbar und eigene Themes nach Bestätigung löschbar; Systempaletten bleiben geschützt. Die Auswahl im Ziel-Editor ist begrenzt, mit „Mehr anzeigen“ und Plus in der Überschrift. Aktueller Integrationsstatus: GitHub #33.

Die normale Emulator-App enthält auf ausdrücklichen Nutzerwunsch vier aktive Demoziele, ein archiviertes Ziel, Zwischenziele, Todos und zwei eigene Themes. Vor diesem Update wurde ihre private Datenbank lokal unter `outputs/before-time-ring.tar` gesichert. Diesen Bestand erhalten, Gerätetests weiterhin ausschließlich mit dem separaten Testpaket ausführen.

## Kompakte Aktionen und eigene Themes · 18.09.2026

PR #30 hat die ersten Zielfarben integriert. Folgeauftrag #31 setzt die Plus-Aktionen in die Überschriften, Zielaktionen und Todo-Historie an den unteren Bildschirmrand und erweitert Themes um vier zentrale Farbrollen. Eigene Themes sind in Einstellungen/Darstellung und per Shortcut im Ziel-Editor erstellbar/bearbeitbar. Schema 6, Backupformat 5; frühere Daten und Backups bleiben unterstützt. Aktueller Branch: codex/compact-actions-custom-themes; Integrationsstatus in GitHub.

**Vorfall beim Android-Test:** Die zuvor verwendete ABI-Split-APK hatte Versionscode 4001. Beim nächsten Flutter-Drive-Test mit Code 1 deinstallierte Flutter automatisch die normale App trotz `--keep-app-running`. Die vorherige lokale Emulator-Datenbank war danach nicht mehr vorhanden. Nur eine alte synthetische Test-Sicherung wurde gefunden; keine Wiederherstellung realer Inhalte möglich. Der Nutzer wurde informiert. Anschließend wurde die normale App neu gestartet. Künftig werden Test-Entrypoints unter integration_test automatisch als separates Android-Paket de.anurag.guided_notes.integration gebaut. Keine ABI-Splits mehr für normale Emulator-Updates; kleinere APK stattdessen mit --target-platform android-x64. Ein neuer isolierter Test prüft die unveränderte normale Datenbank per Prüfsumme. Frühere pauschale Aussagen, --keep-app-running verhindere jeden Datenverlust, sind überholt.

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

## Todo-Zeiträume · 19.09.2026

PR #37 integriert, APK 0.2.1 veröffentlicht. Folgeänderung 0.2.2+4 setzt das kurze Datum neben Heute/Diese Woche und ersetzt den Wochen-Zähler durch Anzahl plus Fortschrittsbalken zwischen Minus/Plus. Hinweise und Speicherung bleiben unverändert. Vor dem Update aktueller normaler Emulator-Bestand unter outputs/before-todo-periods.tar gesichert.

## Blinkende Controls beim Speichern · 19.09.2026

PR #38 integriert, APK 0.2.2 veröffentlicht. Version 0.2.3+5 entfernt die globale UI-Benachrichtigung für den kurzzeitigen Schreibschutz und lädt bei Todo-Zähleränderungen nur betroffene Daten nach. Schreibschutz und Transaktionen bleiben erhalten; Formulare verwenden ihre lokalen Busy-Zustände. 56 Tests einschließlich langsamer Speicherung und inkrementellem Snapshot-Abgleich. Keine Schemaänderung. Performance-Nachweise und Grenzen stehen in docs/validation.md.

## Feine Beiträge und Wochenabschluss · 19.09.2026

#40: Zwei Auswahlräder für ganze Prozent (0–100) und wechselnde Nachkommastufen. Unter 2: Zehntel plus Viertel/drei Viertel, bei 2: 0/0,2/0,4/0,5/0,6/0,8, bei 3: Viertel, bei 4: halbe, ab 5: ganze Prozent. Neue Zuordnung aktiviert 2,5 %. Wochenmodus „je Wiederholung“ oder „bei vollständiger Wochenaufgabe“; Abschlussbeitrag wird sofort bei der letzten Wiederholung gebucht und beim Rückgängigmachen zurückgenommen. Modusänderungen beeinflussen nur neue Buchungen.

Schema 9 speichert Fortschritt und Beiträge als ganzzahlige Hundertstel; Migration erhält Daten, IDs, Autoinkrement-Zähler und frühere Beiträge. Backup 8 enthält den Wochenmodus, liest Versionen 1–7 weiterhin. Anzeigen nutzen deutsche Dezimalzahlen. Die Performance-Korrektur aus PR #39 bleibt erhalten. Version 0.3.0+6 nutzt den vorhandenen privaten Release-Schlüssel. Aktueller GitHub-Stand: #40.

Abschlussprüfung dieser Erweiterung: native Android-Bedienung, Dateineustart und signiertes Update erfolgreich. Aktuelle Benutzerdaten mit outputs/before-fine-progress.tar und outputs/after-fine-progress.tar semantisch verglichen und erhalten. Diese Sicherungen bleiben lokal. Als Datumstrenner ist ausdrücklich der normale Bindestrich gewünscht: 14.9-20.9.

## Schmaleres Nachkomma-Rad · 19.09.2026

Version 0.3.1+7 kürzt die Nachkomma-Beschriftungen (00 → 0, 20 → 2, 50 → 5; 25 bleibt 25). Das linke und rechte Rad teilen sich den Platz im Verhältnis 3:2. Prozentwerte, Speicherung und Buchungsregeln bleiben unverändert. Nutzerwunsch für weitere optische Anpassungen: zweite visuelle Prüfung anhand aktueller Screenshots mit Bewertung 1–10, mindestens 6,5 anstreben.

Prüfung: Analyse ohne Befunde, alle 60 Tests einschließlich großer Schrift sowie nativer Android-Darstellungstest erfolgreich. Zweiter Reviewer: Hell 8/10, Dunkel 7,5/10, insgesamt 7,5/10; keine notwendige Korrektur. Beurteilung der Screenshots bei 2,5 %, keine pauschale visuelle Prüfung aller Nachkommastufen. Normale Emulator-App per Update geöffnet; Datenbank-Prüfsumme vor/nach Installation identisch. Sicherung: outputs/before-compact-fraction.tar.

Nachfolgender Nutzerwunsch in derselben Version: einheitliche Nachkommastufen für alle ganzen Prozentwerte (0; 0,1; 0,2; 0,25; 0,3; 0,4; 0,5; 0,6; 0,7; 0,75; 0,8; 0,9). Beim Wechsel der Ganzzahl bleibt der Bruchteil erhalten, nur bei 100 % wird er auf 0 begrenzt. 60 Tests erneut erfolgreich, einschließlich 99,25 → 100 und vollständigem Speichern/Erledigen/Undo mit 8,5 %. Android-Abschlussprüfung wird mit dem aktualisierten Stand wiederholt.

## Todos im Zwischenziel-Editor · 19.09.2026

Version 0.3.1+7 bündelt die einheitliche Prozentwahl und #43. Status und Frist stehen nebeneinander, mit Umbruch bei großer Schrift. Verknüpfte aktuelle Todos erscheinen in täglich/wöchentlich gruppierten Karten. Beide Ansichten verwenden dieselben TodoGroup/TodoRow-Komponenten. Plus wählt das Zwischenziel vor und aktiviert 2,5 %. Neue Zwischenziele zuerst speichern. Vor Todo-Aktionen werden offene Zwischenziel-Änderungen gespeichert; ein kurzer Hinweis erklärt das. Neue Beiträge aktualisieren Fortschritt und Status im Editor, sodass späteres Speichern sie nicht überschreibt.

Analyse ohne Befunde; 61 Tests einschließlich gemeinsamer Zähler, Neuanlage mit Zuordnung, manueller Fortschrittsänderung vor Erledigung, Rücknahme, anschließendem Speichern und großer Schrift. Nativer Android-Test in Hell/Dunkel erfolgreich. Zweiter Screenshot-Reviewer: beide Modi 8/10. Drei lokal erzeugte Testmotive im Emulator unter Downloads/The-Guide-Testbilder (hell, dunkel, Hochformat); lokale Kopien outputs/testbilder. Keine Nutzerdaten durch Testdaten ersetzen.
