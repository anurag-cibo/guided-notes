# Speicherung und Migration

## Schema 12 und Backupformat 11: Messskalen · 19.09.2026

Zwischenziele ergänzen motivation, start_value, target_value, current_value und unit. Messwerte verwenden ganze Hundertstel. Das bisherige progress-Feld bleibt als normalisierter Prozentanteil für Status und Zielmittel erhalten und wird atomar mit dem Messwert aktualisiert. Ein nur gerundeter Wert nahe 100 wird nicht als Erreichen gewertet. Start/Ziel und Messwert unterstützen zwei Nachkommastellen, Auf-/Abwärtsrichtung sowie negative Werte; absolute Werte und die Gesamtstrecke sind auf eine Milliarde begrenzt. Einheit: maximal 30 Zeichen, leer bedeutet einheitenlos.

Die Todo-Tabellen werden mit größeren Beitragsgrenzen neu aufgebaut. Alle IDs, Fremdschlüssel, Zeilen und der AUTOINCREMENT-Höchststand bleiben erhalten. Beiträge stehen weiterhin in progress_increment, nun als Menge der Zwischenziel-Einheit. Das neue value_amount im Beitragsjournal speichert die tatsächlich gebuchte Menge mit Vorzeichen; das alte amount bleibt als normalisierter Anteil erhalten. Rücknahme verwendet ausschließlich value_amount, unabhängig von späteren Beitrags-/Skalenänderungen, und begrenzt auf die aktuelle Skala.

Migration: vorhandene Zwischenziele erhalten Start 0, Ziel 100, Einheit %, current_value=progress und leeres Warum. Frühere Beiträge übernehmen value_amount=amount. Bestehende Inhalte werden weder als Motivation umgedeutet noch umgerechnet. Neue und im Editor gespeicherte Zwischenziele verlangen ein eigenes nichtleeres Warum. Alte Daten und alte Backups ohne Warum bleiben lesbar und Todo-Buchungen weiterhin möglich.

Backupformat 11 ergänzt Motivation, Start/Ziel/Messwert/Einheit und valueAmount je Beitrag. Import prüft Skala, Wertebereich, Zwei-Nachkommastellen-Präzision, Normalisierung, Status und Beziehungen. Formate 1–10 bleiben lesbar und erhalten die bisherige Prozentskala. Änderungen an der Einheit sind Umbenennungen ohne automatische Mengen-Umrechnung; frühere Buchungen behalten ihre numerische Menge und Richtung.


## Schema 11 und Backupformat 10: Reihenfolge und Zuordnung · 19.09.2026

Die Spalte `sort_order` in `goals` und `milestones` speichert die Reihenfolge, unabhängig von stabilen IDs. Migrationen übernehmen die bisherige ID-Reihenfolge. Neue Einträge kommen ans Ende; bei Gleichstand dient die ID als stabile Zweitsortierung. Verschieben schreibt die Reihenfolge der betroffenen Liste atomar. Archivierte Ziele sind nicht verschiebbar.

Beim Wechsel eines Zwischenziels ändert sich nur seine Zielzuordnung und Position, nicht seine ID, Fortschritt, Status, Frist, Todo-Verknüpfungen oder historischen Beiträge. Der durchschnittliche Zielfortschritt wird weiterhin aus der aktuellen Zuordnung abgeleitet. Der bewusst gesetzte Zielerfolg bleibt unverändert. Rücknahme einer früheren Todo-Erledigung wirkt weiterhin auf dasselbe Zwischenziel.

Backupformat 10 definiert die Position in den Ziel- und Zwischenziel-Arrays als Reihenfolge. Der Import übernimmt diese Positionen; zusätzliche technische Rangfelder sind im JSON nicht nötig. Formate 1–9 bleiben lesbar. Tests decken Migration aus Schema 10, Dateineustart, Backup-Rundlauf, Wechsel in ein anderes Ziel, Todo-Rücknahme und unveränderte Daten bei ungültigen Ablagezielen ab.


## Schema 10 und Backupformat 9: Cover-Sichtbarkeit · 19.09.2026

Ein boolesches Feld goals.show_card_cover (0/1, Standard 1) steuert ausschließlich das Cover auf Zielkarten. Ausgeschaltete Cover behalten ihre Bildbytes. Die Migration 9 → 10 ergänzt nur diese Spalte; vorhandene Fortschritte, Beiträge, IDs, Bilder und Einstellungen bleiben unverändert. Migrationen aus 1–8 führen zunächst ihre bisherigen Schritte bis Schema 9 aus. Die Hundertstelumrechnung erfolgt ausschließlich bei Ausgangsversionen unter 9.

Backupformat 9 enthält showCardCover pro Ziel als erforderlichen booleschen Wert. Formate 1–8 bleiben lesbar und erhalten aktivierte Cover. Import und reguläres Speichern erhalten den Schalter, auch bei Änderungen anderer Zielfelder. Das Standardmotiv wird aus dem Zieltheme gezeichnet und muss nicht als Bilddatei gespeichert werden.


## Schema 8 und Backupformat 7: Todo-Verknüpfungen

`todo_templates` und `todo_entries` ergänzen `milestone_id` (optional, ON DELETE SET NULL) und `progress_increment` (0–100, 0 deaktiviert Tracking). Neue Zeiträume übernehmen die Vorlage. Eine Änderung der Zuordnung aktualisiert auch den aktuellen Zeitraum, ohne bisherige Erledigungen nachträglich zu buchen.

`todo_progress_credits` speichert pro Vorlage, Zeitraum und Erledigungsnummer das damals zugeordnete Zwischenziel, den tatsächlich gutgeschriebenen Betrag sowie den vorherigen Status. Zähler, Zwischenziel und Beitrag ändern sich in derselben Transaktion. Rücknahme entfernt den letzten Beitrag dieses Todos; Begrenzung bei 100 %, geänderte Zuordnungen und gelöschte Zwischenziele bleiben dadurch nachvollziehbar. Nullbeiträge werden ebenfalls gespeichert. Vor Schema 8 vorhandene Erledigungen haben keine Beiträge und verändern bei Rücknahme keinen Fortschritt. Löschen eines Zwischenziels nullt seine Referenzen, Löschen eines Todo-Zeitraums entfernt seine Beiträge per Cascade.

Backupformat 7 enthält Zuordnungen, Beitragskonfiguration und Beitragszeilen. Import prüft Referenzen, Wertebereiche, eindeutige Erledigungsnummern und deren Zugehörigkeit zu erledigten Todo-Einträgen. Die gespeicherten Zwischenzielstände werden übernommen, Beiträge nicht erneut ausgeführt. Formate 1–6 erhalten unabhängige Todos ohne Beiträge. Migrationen aus Schema 1–7 bewahren alle bestehenden Inhalte.

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

## Hundertstel und Wochenabschluss · 19.09.2026

Fortschritt und Todo-Beiträge werden intern und in SQLite als ganzzahlige Hundertstel gespeichert (100 % = 10000). JSON-Backups Version 8 enthalten lesbare Prozentzahlen und progressMode; ältere Backups werden als je-Wiederholung-Modus gelesen. Migrationen aus Schema 1–8 werden unterstützt. Nach den bisherigen Zwischenschritten kopiert die Migration auf Schema 9 abhängige Tabellen, baut die angepassten Constraints in FK-Reihenfolge neu auf und übernimmt Werte mit Faktor 100. Ziele/Bilder/Einstellungen bleiben unverändert. Die IDs und bisherigen Autoinkrement-Stände werden erhalten. Die Migration läuft atomar.
