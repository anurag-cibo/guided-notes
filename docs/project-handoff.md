# Projektübergabe · 17.09.2026

Diese Momentaufnahme hält die bisherige Arbeit und das Nutzerfeedback für weitere Chats fest. Sie ist keine zweite Aufgabenliste; aktueller Status und Akzeptanzkriterien stehen in den [GitHub Issues](https://github.com/anurag-cibo/guided-notes/issues).

## Ergebnis und Rückmeldung

Die ursprünglich als Notiz-App bezeichnete Anwendung ist inzwischen ein Ziele-/Zwischenziele-Prototyp mit dem flexiblen Arbeitsnamen **The Guide**. Der Nutzer wollte zunächst eine startbare Android-App und modularen, leicht erweiterbaren Code. Diese Basis ist vorhanden.

Am 17.09.2026 wurde der zuvor unsichtbare Test-Emulator mit einem sichtbaren Fenster gestartet und die normale App geöffnet. Der Nutzer bestätigt: Die App startet und funktioniert grundsätzlich, ist aber sehr rudimentär und gestalterisch noch nicht hübsch. Das ist eine erste informelle Rückmeldung, keine vollständige Funktionsabnahme oder mehrtägige Nutzererprobung. Konkrete Probleme einzelner Screens, Farben oder Bedienhandlungen wurden noch nicht benannt.

**Für die Fortsetzung:** Die aktuelle Oberfläche ist ein funktionierender Ausgangspunkt, kein freigegebenes Enddesign. Gemeinsam die sichtbaren Screens anschauen und daraus konkrete gestalterische Verbesserungen ableiten. Die bisher gewünschte Richtung bleibt ruhig, minimalistisch und selbsterklärend. Die vorhandene UI-Referenz ist Inspiration, keine verbindliche Vorlage. Ein neues Design oder eine neue Funktionsrunde wurde mit dieser Dokumentationsaktualisierung noch nicht beauftragt.

## Bisher umgesetzt

Über [PR #24](https://github.com/anurag-cibo/guided-notes/pull/24) nach erfolgreicher Build-CI auf `main` zusammengeführt; Merge-Commit `8c1eac1`. Damit wurden die Issues #1, #2, #3, #5, #6, #7, #8 und #10 geschlossen.

- Flutter-Android-Projekt, festgelegte SDK-Version, deutsche Lokalisierung und GitHub Actions mit Debug-APK-Artefakt.
- Produktkern, drei synthetische Beispiele, erste Nutzungsstrecke, Status-/Fortschritts-/Zeitregeln und reduzierter Screenflow dokumentiert.
- Ziele anlegen und bearbeiten, Motivation, optionales Emoji und optionale Frist; höchstens fünf nicht archivierte Ziele.
- Zwischenziele nach Ziel gruppiert, mit Status und Fortschritt; direkte Eintragssprünge und Cluster-Auswahl für lange Listen.
- Details sowie Archivieren, Wiederherstellen und bestätigtes endgültiges Löschen bereits im Code vorhanden. Die separaten Issues #9 und #11 wurden in diesem Paket nicht geschlossen; bei Fortsetzung ihre Kriterien und noch nötigen gezielten Prüfungen abgleichen.
- Offline-Speicherung mit Drift/SQLite, Fremdschlüsseln, Transaktionen und zusätzlicher Absicherung der Fünf-Ziele-Grenze in der Datenbank.
- Subagenten dürfen laut AGENTS.md eingesetzt werden, wenn die Gesamtkosten einschließlich Koordination und Prüfung sinken, ohne Qualität einzubüßen. Bisher wurde ohne Subagenten gearbeitet.

## Festgelegte Grundlagen

Fünf **aktive**, nicht fünf insgesamt gespeicherte Ziele. Erreichte Ziele zählen bis zum ausdrücklichen Archivieren mit. Zielfortschritt ist das gleichgewichtete Mittel der Zwischenziele; die bewusste Zielerfolg-Markierung bleibt davon getrennt. Erreichen archiviert nicht automatisch. Fristen sind optionale Kalenderdaten, keine zweite Fortschrittsanzeige. Motivation genügt zunächst als Freitext; kein eigener Notizbereich.

Details: [Produktentscheidungen](product-decisions.md). Speicherung und künftige Schemaänderungen: [Speicherstrategie](storage.md). Routinen, Bilder, Streaks, Hell-/Dunkelwahl, Cloud und Accounts sind nicht Teil der aktuellen Umsetzung. Export mit geprüfter Wiederherstellung (#12) fehlt noch vor Nutzung mit wichtigen eigenen Daten. Nutzererprobung und Vereinfachung bleiben in #4.

## Technischer Einstieg

Flutter **3.47.4**, Dart **3.13.3**, JDK 21. SDK lokal unter dem ignorierten `work/flutter`; keine globale Flutter-PATH-Einrichtung nötig. Der Wrapper `tool/flutter.ps1` nutzt das lokale SDK, `FLUTTER_ROOT` oder Flutter im PATH.

```powershell
.\tool\flutter.ps1 devices
.\tool\flutter.ps1 run -d emulator-5554
```

Der vorhandene AVD heißt `Medium_Phone_API_36.0` (Android 16 / API 36, x86_64). Bei der Übergabe war die App im sichtbaren Emulator geöffnet; in späteren Chats den tatsächlichen Gerätestatus erneut prüfen. Paket/Activity: `de.anurag.guided_notes/.MainActivity`. Wenn der Emulator nicht läuft, über den Device Manager in Android Studio öffnen. App-Daten erhalten; zum normalen Testen nicht deinstallieren oder den Emulator zurücksetzen.

Der normale auslieferbare Debug-Build liegt lokal unter `outputs/the-guide-debug.apk`. Screenshots des synthetischen Teststands und des leeren Starts liegen unter `outputs/android-goals.png` und `outputs/android-empty.png`. `outputs/` und das SDK sind absichtlich nicht in Git enthalten; auf einem anderen Rechner APK neu bauen oder das CI-Artefakt verwenden. Die Integrationstests können die APK im Build-Verzeichnis durch einen Test-Einstieg ersetzen; für normales Ausprobieren `flutter run` oder erneut `flutter build apk --debug` verwenden.

Architektur: `domain` für Modelle und Fachregeln, `data` für Datenbank und Repository, `application` für den Controller, `presentation` für Screens und Formulare. Theme und App-Einstieg in `lib/app.dart`. Flutter-Navigator und ChangeNotifier; kein zusätzliches State-/Routing-Paket. Gestaltung lässt sich überwiegend in `presentation` und `app.dart` ändern, ohne die Datenstruktur anzufassen.

## Bereits nachgewiesene Qualität

Elf Fachregel-, Persistenz-, Fehler- und Widgettests, Formatierung und Analyse bestanden. Android-Debug-Build lokal und in [GitHub-CI](https://github.com/anurag-cibo/guided-notes/actions/runs/35148618767) erfolgreich. Zwei Android-Integrationstests belegen den ersten Ablauf und erhaltene Daten nach vollständigem Prozessneustart im Flugmodus. Große Schrift und ein Sprung zum 80. Zwischenziel wurden ebenfalls geprüft.

Der Test-Runner deinstalliert die App standardmäßig am Ende: Für die zweiphasige Persistenzprüfung ist `--no-uninstall` nötig. Tests nur mit Testdaten ausführen; sie erzeugen und entfernen ihr synthetisches Ziel. Vollständige Befehle und Grenzen des Nachweises: [README](../README.md) und [Validierung](validation.md).
