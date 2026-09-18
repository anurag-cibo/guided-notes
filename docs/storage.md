# Speicherung und Migration

## Schema 7 und Backupformat 6: Zeitkreis · 18.09.2026

`goals.started_on` speichert das lokale Startdatum als YYYY-MM-DD. Neue Ziele erhalten es beim Erstellen. Migration aus Schema 1–6 ergänzt eine nullable Spalte; beim ersten Repository-Laden werden fehlende Werte einmalig mit dem aktuellen lokalen Datum gefüllt. Alte Backups ohne Startdatum erhalten es beim Import. Bearbeiten, Archivieren und Wiederherstellen ändern den Start nicht. Der Zeitkreis berechnet Kalendertage unabhängig von Sommerzeit, begrenzt die verstrichene Zeit auf 0–100 % und behandelt fehlende oder bereits verstrichene Fristen separat. Der Zwischenzielfortschritt bleibt unabhängig.

Backupformat 6 erhält `startedOn`; Versionen 1–5 bleiben lesbar. Themes lassen sich atomar löschen: zuerst Referenzen aktiver und archivierter Ziele lösen, dann das eigene Theme löschen. Die gespeicherte Standardpalette und sämtliche Zielinhalte bleiben erhalten; bei Fehlern wird auch das Lösen der Referenzen zurückgerollt. Systempaletten liegen als feste Vorgaben außerhalb dieser Tabelle.

## Schema 6 und Backupformat 5: eigene Themes · 18.09.2026

`goal_themes` speichert Name und vier opake sRGB-Farbwerte (Primär, Sekundär, Akzent, Flächenton). `goals.custom_theme_id` referenziert ein eigenes Theme; die bisherige Farbkennung bleibt als Standardauswahl erhalten. Migrationen aus Schema 1–5 erhalten Inhalte; vorhandene Ziele benötigen kein eigenes Theme. Palette und Darstellung sind getrennt, lesbare Hell-/Dunkelrollen werden zentral abgeleitet.

Backupformat 5 enthält sämtliche eigenen Themes und Zielreferenzen. Import validiert Farbwerte, eindeutige IDs und bestehende Referenzen vor der atomaren Übernahme. Alte Formate 1–4 bleiben unterstützt. Auch allein vorhandene Themes verhindern einen Import; „Alle Inhalte löschen“ entfernt sie nach den Zielen in derselben Transaktion. Ein abgebrochener Import rollt auch bereits eingefügte Themes zurück. Neue Sicherungen benötigen Format-5-Unterstützung.

## Schema 5 und Backupformat 4: Zielfarben · 18.09.2026

Die Spalte goals.color speichert die stabile Farbkennung (forest, ocean, lavender, rose, amber). Migrationen aus Schema 1–4 erhalten alle Inhalte und vergeben forest als Standard. Farbwerte gehören zum Ziel, die globale Hell-/Dunkelwahl bleibt unabhängig. Unbekannte Datenbankwerte werden mit Wald dargestellt; ungültige Farbwerte in neuen Backups werden vor dem Import abgelehnt. Backupformat 4 erhält das Farbthema, Formate 1–3 werden weiterhin gelesen und erhalten Wald. Bilder bleiben ab Format 3 enthalten. Neu exportierte Sicherungen benötigen Format-4-Unterstützung. Die folgenden Abschnitte beschreiben die früheren Erweiterungen.


## Schema 4 und Backupformat 3: Zielbilder · 17.09.2026

Die optionale Spalte `goals.cover_image` enthält die Bildkopie als SQLite-BLOB. Damit sind Bild und Ziel gemeinsam transaktional gespeichert; keine ausgelagerten Dateien, dauerhaften URI-Berechtigungen oder verwaisten Bilder. Entfernen setzt die Spalte auf NULL, endgültiges Löschen entfernt sie zusammen mit dem Ziel. Migrationen aus Schema 1, 2 und 3 ergänzen die fehlenden Strukturen und erhalten bestehende Inhalte.

Androids eigene Bildauswahl lädt Dateien bis 20 MB, prüft Abmessungen, dekodiert mit Sampling, berücksichtigt EXIF-Ausrichtung und speichert ein JPEG bis 1280 Pixel/256 KB. Das Original wird nicht verändert; die Kopie enthält keine ursprünglichen EXIF-Metadaten. Nicht lesbare oder zu große Bilder erzeugen eine Fehlermeldung. Abbruch ändert die Auswahl nicht; bei Activity-Ende wird ein wartender Aufruf beendet.

Backupformat 3 enthält die Bildbytes als Base64 in `coverImage`. Versionen 1 und 2 bleiben lesbar und ergeben Ziele ohne Cover. Vor Import werden Bildgröße, Abmessungen und tatsächliche Dekodierbarkeit geprüft; ungültige Bilddaten verändern keine vorhandenen Inhalte. Die Gesamtgrenze bleibt 10 MB und wird beim Export erklärt, falls viele archivierte Bilder sie überschreiten. Die gerätebezogene Darstellungswahl bleibt außerhalb des Backups.

## Schema 3: lokale Einstellungen · 17.09.2026

`app_settings` speichert gerätebezogene Einstellungen als Schlüssel/Wert; `appearance` kennt `system`, `light` und `dark`. Fehlende oder unbekannte Werte ergeben Systemdarstellung. Migrationen von Schema 1 und 2 laufen schrittweise und ergänzen ausschließlich fehlende Tabellen; Ziele und Todos bleiben unverändert.

Backupformat bleibt 2: Die Darstellungswahl ist eine Geräteeinstellung und gehört nicht zu den gesicherten Inhalten. Sie verhindert keinen Import in eine ansonsten leere App. „Alle Inhalte löschen“ entfernt Ziele, Zwischenziele, Todo-Vorlagen und historische Stände gemeinsam in einer Transaktion. Einstellungen und exportierte Dateien bleiben bestehen. Ein erzwungener Datenbankfehler prüft den vollständigen Rollback; ein weiterer Test prüft Wiederherstellung nach dem Löschen.

## Erweiterung auf Schema 2 und Backupformat 2 · 17.09.2026

Schema 2 ergänzt `todo_templates` (ID, Titel, täglich/wöchentlich, Zielanzahl, aktiv) und `todo_entries` (Vorlagen-ID, Zeitraumdatum, damaliger Titel/Häufigkeit/Zielanzahl, Erledigungsanzahl). `(template_id, period)` ist eindeutig; Fremdschlüssel und CHECKs sichern Beziehungen, positive Ziele und Zählergrenzen. Beendete Vorlagen bleiben erhalten. Die Migration 1 → 2 legt ausschließlich diese Tabellen an; Ziele und Zwischenziele bleiben unverändert. Die folgenden Abschnitte zu Schema/Format 1 beschreiben die Ausgangsversion.

Beim Laden entstehen mit `INSERT OR IGNORE` nur aktuelle Zeiträume aktiver Vorlagen. Historische Zeilen werden nicht aus geänderten Vorlagen rekonstruiert. Anlegen, Bearbeiten, Beenden und Zählen erfolgen in Transaktionen. Die Kalenderregeln stehen in den [Produktentscheidungen](product-decisions.md#todos-tages--und-wochenaufgaben).

Backupformat 2 ergänzt `todoTemplates` und `todoEntries`; Format 1 wird weiterhin gelesen und enthält keine Todos. Import prüft zusätzlich eindeutige Vorlagen/Zeiträume, Tages- bzw. Montagsschlüssel, übereinstimmende Häufigkeiten, Zielanzahlen (1–999; täglich genau 1) und Erledigungsgrenzen. Schon ein vorhandener Todo-Datensatz verhindert einen Import. Alle Inhalte werden gemeinsam in einer Transaktion importiert. Neu erzeugte Sicherungen benötigen eine App mit Unterstützung für Format 5.

Tests verwenden eine echte Schema-1-SQLite-Datei aus `test/fixtures/schema_v1.sql`, prüfen Migration mit archiviertem Ziel und Zwischenziel sowie vollständiges Schließen/Wiederöffnen mit Todos. Zusätzlich geprüft: Kalendergrenzen, ausgelassene Zeiträume, Uhr-Rückstellung, Vorlagenänderungen, Rückgängig, Zählergrenzen und Backup inklusive Rollback bei Schreibfehlern.

## Schema 1

`goals`: stabile automatisch vergebene Integer-ID, Titel, Emoji, Motivation, optionale Frist als `YYYY-MM-DD`, bewusster Zielerfolg und Archivflag. `milestones`: stabile ID, Fremdschlüssel zum Ziel, Titel, Fortschritt, Status und optionale Frist. Kein vorsorgliches Sync-Feld, keine Routinen- oder Ereignistabelle. Anlagereihenfolge entspricht der ID-Reihenfolge; IDs werden nicht wiederverwendet.

SQLite aktiviert bei jeder Verbindung Fremdschlüssel. `ON DELETE CASCADE` verhindert verwaiste Zwischenziele. CHECK-Constraints sichern Titel, boolesche Flags, Statuswerte und konsistenten Fortschritt. Zwei Trigger sichern zusätzlich die Fünf-Ziele-Grenze bei Anlage und Wiederherstellung, unabhängig vom UI. Repository-Transaktionen geben verständliche Fachfehler aus; Schreibfehler werden in der Oberfläche angezeigt. Der Controller blockiert paralleles Speichern desselben UI-Ablaufs.

Drift öffnet die Datei `guide.sqlite` im privaten App-Support-Verzeichnis über einen Hintergrund-Isolate. Die App benötigt für fachliche Funktionen keine Netzwerkverbindung. Debug-Builds enthalten für Flutter-Werkzeuge eine Netzwerkberechtigung. Deinstallation kann lokale Daten entfernen; das Archiv ist kein Backup.

## Änderungen am Schema

Schema 1 ist die erste ausgelieferte Datenbank. Es gibt keine älteren App-Daten, die migriert werden müssten. Die SQL-Schemadefinition liegt zentral in `AppDatabase`. `allTables` ist absichtlich leer: Wir verwenden explizite SQL-Abfragen statt Drift-generierter Tabellenklassen und aktualisieren den Controller nach bestätigten Schreibvorgängen.

Bei jeder zukünftigen Schemaänderung:

1. `schemaVersion` erhöhen und eine explizite Migration `from → to` ergänzen; niemals die Datei löschen oder eine destruktive Neuerstellung als Migration verwenden.
2. Eine reale Datenbank der vorherigen Version als Testfixture erstellen, mit Zielen, archivierten Zielen und Zwischenzielen befüllen und schließen.
3. Mit neuer Version öffnen; IDs, Beziehungen, Titel, Fristen und Status vergleichen. `PRAGMA foreign_key_check` muss leer bleiben.
4. Fehlgeschlagene Migration muss vorhandene Daten erhalten. Neueres Schema mit alter App nicht öffnen/überschreiben. Migration und erneutes Öffnen testen.

Aktuelle Persistenztests verwenden temporäre echte SQLite-Dateien, schließen Verbindungen vollständig und öffnen dieselbe Datei erneut. Sie prüfen zusätzlich Fremdschlüssel, Trigger, Rollback und kaskadierendes Löschen.

## Datensicherung · Format 1

Ein UTF-8-JSON-Dokument mit `format: "the-guide"`, `version: 1`, `goals` und `milestones` enthält alle gespeicherten Felder inklusive IDs, Beziehungen, Motivation, Emoji, Fristen, Zielerfolg und Archivstatus. Das Format ist unabhängig von der SQLite-Schemaversion. Abgeleiteter Fortschritt wird nach dem Import neu berechnet.

Der Export liest einen konsistenten Snapshot in einer Transaktion. Androids Storage Access Framework speichert bzw. öffnet die Datei über einen kleinen MethodChannel; keine zusätzliche Speicherberechtigung und kein Dateiauswahl-Paket nötig. Datei-I/O läuft außerhalb des UI-Threads. Dateien sind unverschlüsselt, maximal 10 MB groß und müssen gültiges UTF-8 enthalten.

Import erfolgt ausschließlich in einen leeren Datenbestand (einschließlich Archiv). Vorhandene Daten werden weder ersetzt noch zusammengeführt. Diese bewusst kleine erste Lösung eignet sich zur Wiederherstellung auf einem neuen Gerät. Vor der Bestätigung zeigt die Oberfläche die Anzahl der Ziele, archivierten Ziele und Zwischenziele.

Der Decoder prüft Formatversion, Feldtypen, positive eindeutige IDs, Beziehungen, maximal fünf aktive Ziele, Status/Fortschritt und reale Kalenderdaten von 1900 bis 2200 entsprechend der Datumsauswahl. Erst nach vollständiger Validierung werden sämtliche Zeilen in einer Transaktion angelegt. Die Leerheitsprüfung geschieht innerhalb derselben Transaktion; ein Fehler rollt alle neuen Zeilen zurück. Es gibt keine Schemaänderung für dieses Feature.

Tests belegen Export/Import-Rundlauf einschließlich Archiv, sämtlicher Statuswerte, Unicode, Fristen und erneuter Dateiöffnung. Fehlerfälle umfassen inkompatible Versionen, ungültige Daten, verwaiste/duplizierte IDs, bestehende Daten und einen erzwungenen Datenbankfehler während des Imports. Ein Android-Gerätetest prüft zusätzlich den echten System-Dateidialog mit temporären Testdatenbanken.
