# Speicherung und Migration

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
