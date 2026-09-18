# The Guide

Eine ruhige Android-App für bis zu fünf aktive Ziele und ihre Zwischenziele. **The Guide** ist ein flexibler Arbeitsname; das Repository heißt weiterhin `guided-notes`.

**Todos-Erweiterung (17.09.2026):** Der dritte Tab „Todos“ bietet wiederkehrende Tagesaufgaben und Wochenaufgaben mit Zielanzahl. Abhaken und Rückgängig werden offline gespeichert. Wochen beginnen montags, der lokale Kalender bestimmt den Zeitraum. Titel und Zielanzahl lassen sich für den nächsten Zeitraum ändern; „Aufgabe beenden“ erhält den aktuellen Stand und die Historie. Vergangene Zeiträume sind nur lesbar. Details: [Todo-Regeln](docs/product-decisions.md#todos-tages--und-wochenaufgaben).

**Stand 17.09.2026:** Die Android-Version läuft. Ziele, Details und Zwischenziele wurden anhand der UI-Inspiration ruhiger gestaltet; Archivaktionen und Datensicherung sind geprüft. Die gestalterische Rückmeldung und mehrtägige Nutzererprobung bleiben in #4 offen. Kontext für weitere Chats: [Projektübergabe](docs/project-handoff.md).

## Erste Version

Ziel anlegen → Motivation festhalten → Zwischenziele hinzufügen → Fortschritt und Status pflegen. Ziele, Zwischenziele, Todos und Archive werden offline in SQLite gespeichert, ohne Konto. Drei Hauptbereiche und klare Zurück-Navigation halten den Ablauf klein.

- Maximal fünf aktive, also nicht archivierte Ziele. Erreichte Ziele zählen bis zum Archivieren mit.
- Beliebig viele Zwischenziele, nach Ziel gruppiert, mit Status, 0–100 % Fortschritt und optionaler Frist.
- Zielfortschritt ist das gleichgewichtete Mittel seiner Zwischenziele. Zielerfolg ist eine separate bewusste Markierung.
- Archivieren erhält alle Inhalte; Wiederherstellen prüft die Fünf-Ziele-Grenze. Endgültiges Löschen verlangt eine Bestätigung und entfernt die zugehörigen Zwischenziele atomar.
- Motivation genügt zunächst als Freitext. Ein eigener Bereich für freie Notizen ist nicht Teil dieses Starts.

Beispiele, genaue Status-/Zeitregeln und der reduzierte Screenflow stehen in [Produktentscheidungen](docs/product-decisions.md). Die [UI-Inspiration](docs/reference/ui-inspiration.png) bleibt eine Anregung und keine verbindliche Spezifikation.

Streaks und Einführung bleiben spätere Ergänzungen. Cloud, Accounts, KI, Kalenderintegration und Zusammenarbeit gehören nicht zum aktuellen Kern.

## Hintergrundbild und Emoji

Beim Anlegen oder Bearbeiten eines Ziels oben **Hintergrundbild auswählen** antippen. Android öffnet die Dateiauswahl; das Bild lässt sich ersetzen oder entfernen. Die App speichert eine lokale, verkleinerte Kopie (maximal 1280 Pixel an der längsten Seite und 256 KB); das Original bleibt unverändert. Eingabedateien dürfen höchstens 20 MB groß sein. Das Bild erscheint als Cover im Ziel und ist im Backup enthalten.

Das Emoji-Feld links neben dem Titel erlaubt ein sichtbares Zeichen, auch zusammengesetzte Emojis oder Flaggen. Ohne Eingabe wird das Standardsymbol verwendet.

## Farbthema pro Ziel

Beim Anlegen oder Bearbeiten eines Ziels unter **Farbthema** Wald, Ozean, Lavendel, Rose oder Sonne wählen. Die Vorschau reagiert sofort; gespeichert wird mit dem Ziel. Das Thema färbt Zielkarten, Cover-Fallback, Detailflächen, Schaltflächen und Fortschrittskreis passend zu Hell- oder Dunkelmodus. Eigene Fotos bleiben unverändert. Bestehende Ziele erhalten Wald; die Auswahl ist auch im Backup enthalten.

## Einstellungen und Darstellung

Das Zahnrad in jedem Hauptbereich öffnet die Einstellungen. Die App folgt zunächst dem Gerät; Hell- und Dunkelmodus können dauerhaft gewählt werden. Beide Darstellungen umfassen Ziele, Zwischenziele, Todos, Formulare und Dialoge. Unter „Allgemein“ stehen Sicherung und bestätigtes Löschen aller Inhalte bereit. Sprache, Benachrichtigungen, Erinnerungen und Impressum sind auf Wunsch als klar gekennzeichnete Platzhalter sichtbar. Dateninformationen und verwendete Lizenzen sind ebenfalls erreichbar.

Theme und Statusflächen liegen in `lib/theme`, Speicherung, Steuerung und Oberfläche der Einstellungen getrennt in `lib/features/settings`. Schema 5 migriert die bisherigen Inhalte ohne Datenverlust. Die Darstellungswahl ist gerätebezogen und wird nicht exportiert.

## Daten sichern

Über das Zahnrad **Einstellungen → Datensicherung** oben rechts lassen sich Ziele, Zwischenziele, Todo-Vorlagen, Tages-/Wochenstände und Archive als JSON-Datei exportieren. Android öffnet die Dateiauswahl für den Speicherort. Die Datei enthält auch Motivationstexte und ist unverschlüsselt; eine Kopie außerhalb des Geräts schützt vor Geräteverlust.

**Wiederherstellen ist nur in einer leeren App möglich**, einschließlich Todos und Historie, beispielsweise auf einem neuen Gerät. Es gibt kein stilles Zusammenführen oder Überschreiben. Vor dem Import werden die Anzahlen der Inhalte zur Bestätigung angezeigt. Ungültige Dateien werden abgelehnt; ein fehlgeschlagener Import wird vollständig zurückgerollt. Exportformat: `the-guide`, Version 4, bis 10 MB. Alte Sicherungen mit Version 1 bis 3 bleiben importierbar. Details: [Speicherstrategie](docs/storage.md).

## Entwicklung starten

Voraussetzungen: Git, **Flutter 3.47.4 / Dart 3.13.3**, Android SDK und JDK 21. CI und lokale Einrichtung verwenden dieselbe Flutter-Version. Android Studio stellt hier JDK und SDK bereit. Flutter verwaltet die durch das Android-Projekt angeforderten Build-Werkzeuge; der erste Build braucht Netzwerkzugriff und kann länger dauern.

```powershell
# Nur beim ersten Einrichten, falls kein passendes Flutter-SDK vorhanden ist:
git clone --depth 1 --branch 3.47.4 https://github.com/flutter/flutter.git work/flutter

# Der Wrapper nutzt FLUTTER_ROOT, das lokale work/flutter oder Flutter im PATH.
.\tool\flutter.ps1 doctor -v
.\tool\flutter.ps1 pub get --enforce-lockfile
.\tool\flutter.ps1 devices
.\tool\flutter.ps1 run -d emulator-5554
```

Ein Android-Gerät mit USB-Debugging oder einen Emulator über den Device Manager in Android Studio starten. Falls Android-Lizenzen noch fehlen: `flutter doctor --android-licenses`. Geräte-ID aus `flutter devices` übernehmen. Für ein vorhandenes SDK im PATH kann überall direkt `flutter` verwendet werden.

```powershell
.\tool\flutter.ps1 analyze lib test integration_test
.\tool\flutter.ps1 test
.\tool\flutter.ps1 build apk --debug
```

Die installierbare APK liegt unter `build/app/outputs/flutter-apk/app-debug.apk`. Es ist ein Entwicklungsbuild mit Debug-Signierung. Änderungen an der Oberfläche lassen sich mit `flutter run` und Hot Reload schnell ausprobieren.

## Aufbau

| Bereich | Verantwortung |
| --- | --- |
| `lib/features/goals/domain` | Unveränderliche Modelle, Statusregeln, Fortschritts- und Kalenderberechnung |
| `lib/data` | SQLite-Schema, Verbindung und Versionsverwaltung mit Drift |
| `lib/features/goals/data` | Parametrisierte Datenzugriffe und atomare Fachoperationen |
| `lib/features/goals/application` | Lade-/Speicherzustand, Fehler und Aktualisierung der Ansichten |
| `lib/features/goals/presentation` | Kleine Screens/Formulare und gemeinsame UI-Elemente |
| `lib/app.dart` | Theme, deutsche Lokalisierung und Einstieg |

Navigator und ChangeNotifier reichen für diesen Ablauf. Keine vorsorglichen Routing-, State-, Sync- oder Ereignisframeworks. Drift wird mit explizitem SQL für Ziele, Zwischenziele, Todos und Einstellungen verwendet; daher kein zusätzlicher Codegenerator. Fachmodell und Widgets kennen keine SQL-Zeilen. Details zur [Speicherung und Migration](docs/storage.md).

## Prüfung und Zusammenarbeit

GitHub Actions prüft Formatierung, Analyse, Fachregel-/Persistenz-/Widgettests und einen Android-Debug-Build. Ein APK-Artefakt steht nach erfolgreichem CI-Lauf bereit. Die Tests decken unter anderem die Fünf-Ziele-Grenze bei schnellen Aktionen, Fremdschlüssel, Transaktionsrollback, Dateineustart, den ersten Bedienablauf, große Schrift und einen Sprung ans Ende einer langen Zwischenzielliste ab.

Der Android-Test läuft in zwei getrennten Prozessen auf einem Testgerät; Phase 2 prüft die Daten der ersten Phase und entfernt ausschließlich ihr synthetisches Testziel:

```powershell
.\tool\flutter.ps1 test integration_test/app_test.dart -d emulator-5554 --no-uninstall
# App vollständig stoppen, optional Flugmodus aktivieren, danach:
.\tool\flutter.ps1 test integration_test/app_test.dart -d emulator-5554 --no-uninstall --dart-define=VERIFY_RESTART=true
```

Nicht gegen einen wichtigen Datenbestand ausführen. Das Testziel heißt `Android-Testziel`; es wird nicht in eine neu installierte App vorbefüllt.

Aktueller Aufgabenstand und Akzeptanzkriterien: [GitHub Issues](https://github.com/anurag-cibo/guided-notes/issues). Arbeitskonventionen: [AGENTS.md](AGENTS.md). Reproduzierbare Prüfungen und Android-Nachweis: [Validierung](docs/validation.md).
