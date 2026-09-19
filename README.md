# The Guide

Eine ruhige Android-App für bis zu fünf aktive Ziele und ihre Zwischenziele. **The Guide** ist ein flexibler Arbeitsname; das Repository heißt weiterhin `guided-notes`.

**Todos-Erweiterung (17.09.2026):** Der dritte Tab „Todos“ bietet wiederkehrende Tagesaufgaben und Wochenaufgaben mit Zielanzahl. Abhaken und Rückgängig werden offline gespeichert. Wochen beginnen montags, der lokale Kalender bestimmt den Zeitraum. Titel und Zielanzahl lassen sich für den nächsten Zeitraum ändern; „Aufgabe entfernen“ blendet ein Todo sofort aus allen aktuellen Listen aus und stoppt Wiederholungen. Historie und bereits gutgeschriebene Zwischenziel-Beiträge bleiben erhalten. Vergangene Zeiträume sind nur lesbar. Details: [Todo-Regeln](docs/product-decisions.md#todos-tages--und-wochenaufgaben).

**Stand 17.09.2026:** Die Android-Version läuft. Ziele, Details und Zwischenziele wurden anhand der UI-Inspiration ruhiger gestaltet; Archivaktionen und Datensicherung sind geprüft. Die gestalterische Rückmeldung und mehrtägige Nutzererprobung bleiben in #4 offen. Kontext für weitere Chats: [Projektübergabe](docs/project-handoff.md).

## Erste Version

Ziel anlegen → Motivation festhalten → Zwischenziele hinzufügen → Fortschritt und Status pflegen. Ziele, Zwischenziele, Todos und Archive werden offline in SQLite gespeichert, ohne Konto. Drei Hauptbereiche und klare Zurück-Navigation halten den Ablauf klein.

- Maximal fünf aktive, also nicht archivierte Ziele. Erreichte Ziele zählen bis zum Archivieren mit.
- Beliebig viele Zwischenziele, nach Ziel gruppiert, mit eigener Messskala, Status und optionaler Frist.
- Zielfortschritt ist das gleichgewichtete Mittel seiner Zwischenziele. Zielerfolg ist eine separate bewusste Markierung.
- Archivieren erhält alle Inhalte; Wiederherstellen prüft die Fünf-Ziele-Grenze. Endgültiges Löschen verlangt eine Bestätigung und entfernt die zugehörigen Zwischenziele atomar.
- Das Warum ist bei der Erstellung eines großen Ziels verpflichtend. Ohne Begründung (auch bei bloßen Leerzeichen) bleibt das Formular offen und zeigt einen Hinweis. Bestehende Ziele ohne Warum bleiben bearbeitbar. Motivation genügt als Freitext. Ein eigener Bereich für freie Notizen ist nicht Teil dieses Starts.

Beispiele, genaue Status-/Zeitregeln und der reduzierte Screenflow stehen in [Produktentscheidungen](docs/product-decisions.md). Die [UI-Inspiration](docs/reference/ui-inspiration.png) bleibt eine Anregung und keine verbindliche Spezifikation.

Streaks und Einführung bleiben spätere Ergänzungen. Cloud, Accounts, KI, Kalenderintegration und Zusammenarbeit gehören nicht zum aktuellen Kern.

## Messwerte und Einheiten

Ein Zwischenziel hat eine **Einheit**, **Startwert**, **Zielwert** und **aktuellen Wert**. Die Auswahl enthält **Prozent**, **Ohne Einheit** und **Eigene Einheit**; bei Eigene Einheit lässt sich direkt im selben Feld etwa Gläser, Seiten oder Kilogramm eintragen. Der Pfeil bleibt zum Wechseln der Auswahl erhalten. Beide Richtungen werden unterstützt, etwa 80 → 100 Seiten oder 100 → 80 kg. Manuelle Zahlen erlauben zwei Nachkommastellen. Der Slider rundet auf eine Nachkommastelle; bereits vorhandene exakte Start-/Zielgrenzen bleiben erreichbar. Der aktuelle Wert liegt zwischen Start und Ziel; Start und Ziel müssen verschieden sein. Einheit und aktueller Wert stehen nebeneinander; der Regler zwischen Start- und Zielwert zeigt seinen Messwert dauerhaft über dem Griff. Bei schmalem Bildschirm oder großer Schrift werden die Felder untereinander angeordnet. Änderungen gültiger Skalengrenzen begrenzen den aktuellen Wert sofort. Todo-Beiträge zeigen die gewählte Einheit und Richtung bereits als ungespeicherte Vorschau; Abbrechen erhält den gespeicherten Stand.

Die Zwischenziellisten zeigen den Messwert und das Ziel, beispielsweise **3 / 12 Bücher**. Der Balken und der Gesamtfortschritt des großen Ziels verwenden den erreichten Anteil der Strecke: 90 auf einer Skala von 80 bis 100 entspricht 50 %. Ein Erreichen des Zielwerts setzt den Status Erreicht. Bestehende Zwischenziele behalten zunächst 0–100 %. Zwischenziele haben kein Warum-Feld.

## Todos und Zwischenziel-Fortschritt

Beim Erstellen oder Bearbeiten einer Aufgabe lässt sich optional ein Zwischenziel über eine durchsuchbare, nach Zielen gruppierte Auswahl zuordnen. **Fortschritt automatisch erhöhen** aktiviert einen Beitrag in dessen Einheit: etwa +1 Buch, +20 Seiten oder bei absteigender Skala −0,5 kg. Die Eingabe ist eine positive Menge; die Skala bestimmt die Richtung. Für die bisherige Skala 0–100 % bleiben die kompakten Prozent-Scrollräder mit ihren Nachkommastufen bestehen. Andere Skalen verwenden ein Zahlenfeld mit Einheit. Vorgabe ist 2,5 bei Standardprozent, sonst 1 beziehungsweise die kleinere Gesamtstrecke.

Wochenaufgaben können je Wiederholung oder erst beim Erreichen aller Wiederholungen beitragen. Der Messwert stoppt am Ziel. Rückgängig entfernt exakt die tatsächlich gebuchte Menge mit ihrer damaligen Richtung, auch nach Neustart, Backup, geänderter Skala oder Zuordnung; das Ergebnis bleibt innerhalb der aktuellen Skala. Beispiel: Bei Ziel 80 kg wird aus 81 kg mit einem Beitrag von 2,5 kg der Wert 80 kg; Rückgängig stellt 81 kg her.

Änderungen an Einheit oder Skala rechnen vorhandene Zahlen und Todo-Beiträge nicht in eine andere Maßeinheit um. Ein Hinweis im Zwischenziel-Editor erinnert bei betroffenen aktiven Todos daran. Bereits gebuchte Mengen bleiben unverändert; neue Erledigungen verwenden die aktuelle Richtung. Titel und Wochenanzahl ändern sich weiterhin erst ab dem nächsten Zeitraum. Archivierte Ziele erhalten keine neuen Beiträge. Löschen eines Zwischenziels erhält die Todos und löst ihre Zuordnung.

„Vergangene Zeiträume“ liegt am Ende des scrollenden Inhalts. Die einzeilige Emoji-Leiste im Zwischenziele-Tab springt beim Antippen direkt zum jeweiligen Ziel. Zielnamen sind per langem Drücken und für Screenreader verfügbar. Nach einem Emoji-Tipp blinkt die Markierung für 180 ms auf und verschwindet direkt, ohne Fade. Die Leiste blendet sich beim Hinunterscrollen aus und beim Hochscrollen wieder ein.

Die Zielüberschriften im Zwischenziele-Tab öffnen die jeweiligen Zieldetails. Die Überschrift „Zwischenziele“ in den aktiven Zieldetails wechselt zum bestehenden Zwischenziele-Tab und springt zur passenden Zielgruppe; wiederholtes Wechseln stapelt keine Detailseiten. Die Plus-Buttons bleiben eigenständige Aktionen.

Antippen eines Zwischenziels in den Zieldetails öffnet direkt seinen Editor; Speichern und Zurück führen zu diesen Zieldetails zurück.

Im Zwischenziel-Editor stehen Status und Frist nebeneinander. Darunter lassen sich die aktuell verknüpften Todos in „Täglich“ und „Wöchentlich“ genau wie im Todos-Tab bedienen. Plus öffnet eine neue Aufgabe mit vorausgewähltem Zwischenziel und passendem Standardbeitrag. Todo-Aktionen speichern zuvor auch offene Änderungen am Zwischenziel; danach bleibt dessen Fortschritt synchron. Neue Zwischenziele zuerst speichern, anschließend können Todos zugeordnet werden.

## Hintergrundbild und Emoji

Beim Anlegen oder Bearbeiten eines Ziels oben **Hintergrundbild auswählen** antippen. Android öffnet die Dateiauswahl; das Bild lässt sich ersetzen oder entfernen. Die App speichert eine lokale, verkleinerte Kopie (maximal 1280 Pixel an der längsten Seite und 256 KB); das Original bleibt unverändert. Eingabedateien dürfen höchstens 20 MB groß sein. Das Bild erscheint als Cover im Ziel und im oberen Bereich seiner Zielkarte. Ohne eigenes Bild wird das vorhandene Standardmotiv im Zieltheme verwendet. Die verbleibenden Tage stehen im Cover-Bereich direkt unter dem Zwischenziel-Status. Auf der ruhigen Fläche darunter stehen nur Fortschrittsbalken und Prozentangabe in einer Zeile, die Prozentzahl rechts. Der Schalter rechts neben Bildauswahl und Papierkorb blendet das Cover ausschließlich auf der Zielkarte ein oder aus; eigenes Bild und Detailcover bleiben erhalten. Die Einstellung wird pro Ziel gespeichert und mitgesichert. Das Bild ist im Backup enthalten.

Das Emoji-Feld links neben dem Titel erlaubt ein sichtbares Zeichen, auch zusammengesetzte Emojis oder Flaggen. Ohne Eingabe wird das Standardsymbol verwendet.

## Farbthema pro Ziel

Beim Anlegen oder Bearbeiten eines Ziels unter **Farbthema** Wald, Ozean, Lavendel, Rose oder Sonne wählen. Die Vorschau reagiert sofort; gespeichert wird mit dem Ziel. Das Thema färbt Zielkarten, Cover-Fallback, Detailflächen, Schaltflächen und Fortschrittskreis passend zu Hell- oder Dunkelmodus. Eigene Fotos bleiben unverändert. Bestehende Ziele erhalten Wald; die Auswahl ist auch im Backup enthalten.

Unter **Einstellungen → Darstellung → Themes** lassen sich eigene Themes erstellen, bearbeiten und nach Bestätigung löschen. Beim Löschen wechseln zugeordnete Ziele auf ihre gespeicherte Standardpalette zurück; Inhalte bleiben erhalten. Die fünf Systemthemes sind geschützt. Das Plus rechts in „Farbthema“ im Ziel-Editor öffnet den Theme-Editor und übernimmt das neue Theme; übrige Eingaben bleiben erhalten. „Mehr anzeigen“ erweitert die begrenzte Auswahl, das gewählte Theme bleibt immer sichtbar. Primärfarbe, Sekundärfarbe, Akzentfarbe und Flächenton werden über Farbfelder oder Hex-Werte gewählt. Änderungen an einem eigenen Theme gelten für alle zugeordneten Ziele. Eigene Themes sind im Backup enthalten und werden bei „Alle Inhalte löschen“ mit entfernt.

Der Kreis rechts vom Zieltitel zeigt die verstrichene Zeit seit dem Anlegen bis zur Frist und innen die verbleibenden Kalendertage. Ohne Frist bleibt er neutral; fällige und überfällige Ziele werden entsprechend beschriftet. Bei älteren Zielen startet die Messung beim ersten Laden der neuen Version, da vorher kein Startdatum gespeichert wurde. Änderungen am Ziel behalten diesen Start bei. Darunter zeigt ein Balken mit Prozentwert den Zwischenzielfortschritt. Das Archiv steht bei kurzen Ziellisten unten und scrollt bei langen Listen hinter den Zielen mit.

Die zentralen Farbrollen stehen in `ThemeColors`, Vorgaben und Ableitung für Hell/Dunkel in `goal_theme.dart`. Karten von Zielen und Zwischenzielen verwenden dieselbe sanfte Flächentönung. Die Statusbezeichnung bleibt unabhängig vom Zieltheme sichtbar. Kleine Plus-Kreise sitzen in den Überschriften; Zielaktionen und Todo-Historie bleiben am unteren Bildschirmrand.

## Einstellungen und Darstellung

Das Zahnrad in jedem Hauptbereich öffnet die Einstellungen. Die App startet bei jedem Neustart im Hellmodus, unabhängig von vorheriger Auswahl und Geräteeinstellung. Dunkelmodus oder Wie das Gerät können für die laufende Nutzung gewählt werden. Beide Darstellungen umfassen Ziele, Zwischenziele, Todos, Formulare und Dialoge. Unter „Allgemein“ stehen Sicherung und bestätigtes Löschen aller Inhalte bereit. Sprache, Benachrichtigungen, Erinnerungen und Impressum sind auf Wunsch als klar gekennzeichnete Platzhalter sichtbar. Dateninformationen und verwendete Lizenzen sind ebenfalls erreichbar.

Theme und Statusflächen liegen in `lib/theme`, Speicherung, Steuerung und Oberfläche der Einstellungen getrennt in `lib/features/settings`. Schema 12 migriert die bisherigen Inhalte ohne Datenverlust. Die Darstellungswahl ist gerätebezogen und wird nicht exportiert.

Ziele lassen sich durch langes Drücken und Ziehen sortieren. Dasselbe gilt für Zwischenziele in den Zieldetails und im Zwischenziele-Tab. Dort kann ein Zwischenziel auch auf die Überschrift eines anderen Ziels oder zwischen dessen Zwischenziele gezogen werden. Todo-Verknüpfungen und bisherige Fortschrittsgutschriften bleiben erhalten; beide Ziel-Fortschritte werden neu berechnet. Die Reihenfolge übersteht Neustarts und Datensicherungen. Am Listenrand wird beim Ziehen automatisch gescrollt; ein eigener Bearbeitungsmodus ist nicht nötig.

Die Emoji-Markierung blinkt beim Tippen für 180 ms auf und verschwindet direkt, ohne Fade. Beim Scrollen wird die gesamte Sprungleiste weich aus- beziehungsweise eingeblendet.

## Daten sichern

Über das Zahnrad **Einstellungen → Datensicherung** oben rechts lassen sich Ziele, Zwischenziele, Todo-Vorlagen, Tages-/Wochenstände und Archive als JSON-Datei exportieren. Android öffnet die Dateiauswahl für den Speicherort. Die Datei enthält auch Motivationstexte und ist unverschlüsselt; eine Kopie außerhalb des Geräts schützt vor Geräteverlust.

**Wiederherstellen ist nur in einer leeren App möglich**, einschließlich Todos und Historie, beispielsweise auf einem neuen Gerät. Es gibt kein stilles Zusammenführen oder Überschreiben. Vor dem Import werden die Anzahlen der Inhalte zur Bestätigung angezeigt. Ungültige Dateien werden abgelehnt; ein fehlgeschlagener Import wird vollständig zurückgerollt. Exportformat: `the-guide`, Version 11, bis 10 MB. Alte Sicherungen mit Version 1 bis 10 bleiben importierbar. Details: [Speicherstrategie](docs/storage.md).

## APK fürs Handy

Installierbare APKs stehen unter [GitHub Releases](https://github.com/anurag-cibo/guided-notes/releases). Die universelle APK am Android-Handy herunterladen, öffnen und gegebenenfalls die Installation für den Browser oder Dateimanager erlauben. Bei einem privaten Repository ist eine GitHub-Anmeldung mit Zugriff nötig. Die App enthält keine Demodaten; vorhandene Daten lassen sich per Datensicherung übertragen.

Release-Builds benötigen den dauerhaft verwendeten privaten Signaturschlüssel und `android/key.properties` mit `storeFile`, `storePassword`, `keyAlias` und `keyPassword`. Beides ist von Git ausgeschlossen. Der Schlüssel liegt auf diesem Rechner unter `work/release-signing/the-guide-release.jks`; Schlüssel und Properties geschützt sichern und bei Aufräumarbeiten erhalten. Spätere Handy-Updates müssen denselben Schlüssel und eine höhere Buildnummer verwenden. Der normale Emulator nutzt weiterhin die separate Debug-Signatur; dort nur Debug-Updates installieren. Ohne Release-Schlüssel bricht ein normaler Release-Build ab, statt unbemerkt eine Debug-Signatur zu verwenden.

```powershell
.\tool\flutter.ps1 build apk --release
# build/app/outputs/flutter-apk/app-release.apk – nicht nach ABI aufteilen.
```

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

## Android-Gerätetests getrennt ausführen

Entrypoints unter `integration_test/` werden automatisch mit der Paketkennung `de.anurag.guided_notes.integration` und dem Namen **The Guide · Test** gebaut. Die normale App bleibt `de.anurag.guided_notes`. Die Trennung ist für explizite Test-Targets mit `flutter drive` geprüft. Vor Verwendung fremder/vorgebauter Test-APKs deren Paketkennung kontrollieren; keine Test-APK mit der normalen Kennung installieren.

Für den vorhandenen x86_64-Emulator kann `flutter build apk --debug --target-platform android-x64` eine kleinere normale APK ohne Änderung des Versionscodes bauen. **Kein `--split-per-abi` im Emulator-Workflow:** ABI-Splits erhöhen den Versionscode, und Flutter kann bei späteren Downgrade-Fehlern automatisch deinstallieren. `--keep-app-running` verhindert nur die Deinstallation am Testende, nicht diesen Installations-Fallback.

## Prüfung und Zusammenarbeit

GitHub Actions prüft Formatierung, Analyse, Fachregel-/Persistenz-/Widgettests und einen Android-Debug-Build. Ein APK-Artefakt steht nach erfolgreichem CI-Lauf bereit. Die Tests decken unter anderem die Fünf-Ziele-Grenze bei schnellen Aktionen, Fremdschlüssel, Transaktionsrollback, Dateineustart, den ersten Bedienablauf, große Schrift und einen Sprung ans Ende einer langen Zwischenzielliste ab.

Der Android-Test läuft in zwei getrennten Prozessen auf einem Testgerät; Phase 2 prüft die Daten der ersten Phase und entfernt ausschließlich ihr synthetisches Testziel:

```powershell
.\tool\flutter.ps1 drive --driver integration_test/screenshot_driver.dart --target integration_test/app_test.dart -d emulator-5554 --keep-app-running
# App vollständig stoppen, optional Flugmodus aktivieren, danach:
.\tool\flutter.ps1 drive --driver integration_test/screenshot_driver.dart --target integration_test/app_test.dart -d emulator-5554 --keep-app-running --dart-define=VERIFY_RESTART=true
```

Nicht gegen einen wichtigen Datenbestand ausführen. Das Testziel heißt `Android-Testziel`; es wird nicht in eine neu installierte App vorbefüllt.

Aktueller Aufgabenstand und Akzeptanzkriterien: [GitHub Issues](https://github.com/anurag-cibo/guided-notes/issues). Arbeitskonventionen: [AGENTS.md](AGENTS.md). Reproduzierbare Prüfungen und Android-Nachweis: [Validierung](docs/validation.md).
