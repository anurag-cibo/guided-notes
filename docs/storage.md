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

Aktuelle Persistenztests verwenden temporäre echte SQLite-Dateien, schließen Verbindungen vollständig und öffnen dieselbe Datei erneut. Sie prüfen zusätzlich Fremdschlüssel, Trigger, Rollback und kaskadierendes Löschen. Export und validierter Import sind ein eigenes noch offenes Feature (#12).
