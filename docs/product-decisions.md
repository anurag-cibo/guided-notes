# Erste Version: Ziele und Zwischenziele

Entscheidungsstand vom 16.09.2026 für #1, #5 und #6. Diese kleinen, reversiblen Produktentscheidungen konkretisieren den beauftragten ersten Ablauf; nach dem Nutzungsversuch können wir sie ändern.

## Produktkern (#1)

The Guide bleibt ein austauschbarer Arbeitsname. Die erste Version führt vom leeren Bildschirm über ein Ziel mit Motivation zu einem Zwischenziel und dessen Erreichen. Freie Notizen erhalten keinen eigenen Bereich: Motivation und Zwischenzieltitel reichen für diesen Ablauf. Routinen, Bilder, Streaks, Accounts, Sync und ein Tutorial folgen nicht automatisch.

| Synthetisches Ziel | Zwischenziele | Beispiel für Fortschritt |
| --- | --- | --- |
| Einen 5-km-Lauf schaffen | Trainingsplan wählen; 20 Minuten durchlaufen; 5 km laufen | 100 %, 50 %, 0 % ergeben 50 % |
| Ein kleines Buch schreiben | Gliederung; erster Entwurf; Überarbeitung | 100 %, 25 %, 0 % ergeben gerundet 42 % |
| Balkon begrünen | Pflanzen auswählen; Kästen aufstellen; einpflanzen | Drei erreichte Zwischenziele ergeben 100 % |

Erste Nutzungsstrecke: „Ziel hinzufügen“ → Titel, optional Emoji/Motivation/Frist → Zieldetail → „Zwischenziel hinzufügen“ → Titel → Eintrag öffnen → Status „Erreicht“ → Fortschritt im Ziel sehen. Änderungen werden lokal gespeichert. Der Zustand muss einen vollständigen App-Neustart überstehen.

## Fachregeln (#5)

- Höchstens **fünf nicht archivierte Ziele**. Erreichte Ziele zählen mit, bis sie ausdrücklich archiviert werden. Archivierte Ziele haben kein Mengenlimit. Wiederherstellen bei fünf aktiven Zielen wird mit einer verständlichen Meldung abgelehnt, ohne Daten zu ändern.
- Zwischenziele haben einen ganzzahligen Fortschritt von 0 bis 100. „Noch nicht begonnen“ bedeutet 0 %, „Erreicht“ 100 %. Die übrigen Zustände erlauben 0–99 %. Beim Wechsel weg von „Erreicht“ muss wieder ein Wert unter 100 gewählt werden. Bei 100 % wird der Status „Erreicht“ gesetzt; bei einem positiven Wert wechselt „Noch nicht begonnen“ zu „Im Plan“.
- Zielfortschritt ist das ungewichtete arithmetische Mittel seiner Zwischenziele, zur Anzeige auf ganze Prozent gerundet. Ohne Zwischenziele: „Noch keine Zwischenziele“, kein erfundener Fortschritt. Hinzufügen/Ändern/Löschen eines Zwischenziels berechnet das Mittel neu; dadurch darf es sinken.
- Zielerfolg ist eine bewusste, separate Markierung. 100 % Zwischenzielfortschritt markiert das große Ziel nicht automatisch als erreicht. Ein Ziel kann auch ohne Zwischenziele erreicht sein; sein inhaltlicher Erfolg ist nicht dieselbe Größe wie der berechnete Zwischenzielfortschritt.
- Es gibt eine optionale **Frist als lokales Kalenderdatum**, keinen Zeitkreis und kein Startdatum. Anzeige: „Ohne Frist“, „Heute fällig“, „Noch … Tage“ oder „… Tage überfällig“. Der ganze Fälligkeitstag zählt; Sommerzeit wird durch Kalenderdatumsarithmetik berücksichtigt. Bei erreichten Einträgen steht „Erreicht“ statt eines Überfälligkeitsdrucks. Frist und Fortschritt stehen getrennt.

| Gespeicherter Status | Anzeige | Bedeutung |
| --- | --- | --- |
| notStarted | Noch nicht begonnen | Noch keine Umsetzung, 0 % |
| onTrack | Im Plan | Wird bearbeitet |
| offTrack | Außer Plan | Benötigt eine Anpassung, bleibt bearbeitbar |
| onHold | Pausiert | Bewusst unterbrochen, Fortschritt bleibt erhalten |
| achieved | Erreicht | Zwischenziel vollständig umgesetzt, 100 % |

„Gefährdet“ entfällt zunächst: Es ist ohne Nutzungserfahrung nicht klar von „Außer Plan“ abzugrenzen. Pausiert und Außer Plan bleiben getrennt. Status wird immer mit Text dargestellt; Farbe ist nur ergänzend.

Archivieren verändert weder Fortschritt noch Zielerfolg. Es verbirgt das Ziel einschließlich seiner Zwischenziele aus aktiven Ansichten. Wiederherstellen behält IDs, Inhalte, Status und Fristen. Beispiel: Nach Archivieren von Ziel A sind vier Plätze belegt; A kann wiederhergestellt werden. Wurde inzwischen Ziel F angelegt, bleibt A unverändert im Archiv. Endgültiges Löschen verlangt eine Bestätigung mit Hinweis auf alle zugehörigen Zwischenziele; das Löschen geschieht atomar. Ein Zwischenziel zu löschen verändert den berechneten Fortschritt, niemals andere Zwischenziele.

## Oberfläche und Navigation (#6)

Zwei beschriftete Hauptbereiche: **Ziele** und **Zwischenziele**. Ziele ist der Startbereich. Details, Formulare und Archiv sind eigene Seiten im Navigator. Android-Zurück und der sichtbare Zurück-Pfeil schließen die aktuelle Seite und führen zur vorherigen Ansicht; vom Zwischenziele-Hauptbereich führt Zurück zuerst zu Ziele. Es gibt keine externen Deep Links.

```text
Ziele                           Zieldetail
  [Emoji  Zielname          >]     Titel                 [Bearbeiten]
  [Emoji  Zielname          >]     Warum? / Motivation
  [+ Ziel hinzufügen]             Zwischenzielfortschritt / Frist
  Archiv >                        Zwischenziele (antippbar)
                                  [+ Zwischenziel hinzufügen]
[Ziele] [Zwischenziele]            Ziel erreicht / Archivieren

Zwischenziele                   Archiv
  [Ziel wählen / hinspringen]      Archivierte Ziele > Detail
  Emoji Zielname                  Wiederherstellen / Löschen
    Zwischenziel > Bearbeiten
    Status · Fortschritt · Frist
  [+ Zwischenziel hinzufügen]
```

- Ziel-Plus ist im Leerzustand und unter den Karten sichtbar, bei fünf Zielen ausgeblendet. Archiv bleibt immer darunter erreichbar.
- Zwischenziel-Plus liegt beim jeweiligen Ziel; es verlangt daher keine erneute Auswahl des Elternziels. Die Übersicht gruppiert stabil nach Ziel-ID/Anlagereihenfolge, innerhalb der Gruppe nach Zwischenziel-ID. Die Kopfzeile bietet bei mehreren Zielen eine beschriftete Cluster-Auswahl. Ein Sprung aus dem Detail fokussiert genau den gewählten Eintrag.
- Leerzustände erklären nur die nächste mögliche Handlung: „Noch keine Ziele“ bzw. „Noch keine Zwischenziele“. Ein leeres Archiv zeigt „Keine archivierten Ziele“. Ladezustand und Fehler mit Wiederholen sind sichtbar.
- Emoji ist optional und ohne Berechtigungen nutzbar. Bilder werden verschoben. Kein Einstellungszugang ohne tatsächliche Einstellung, keine leeren Routinen-Tabs und kein Begrüßungsblock.
- Material-Elemente mit mindestens 48 dp Touch-Fläche, flexible statt fester Texthöhen, scrollende Formulare und große Schrift. Fortschritt wird einmal pro Kontext beschriftet; Frist ist eine Textzeile statt einer zweiten Prozentanzeige. Statusinformationen bleiben ohne Farben verständlich.

Die technische Basis verwendet Flutter-Navigator und Listenable/ChangeNotifier. Ein State- oder Routing-Paket hat für diesen begrenzten Ablauf keinen konkreten Nutzen. Speicherung, Fachmodell und Widgets werden getrennt, damit spätere Gestaltung keine Datenmigration erfordert.

## Todos: Tages- und Wochenaufgaben

**Erweiterung #35:** Todos dürfen optional einem Zwischenziel zugeordnet werden. Tracking ist ein getrennter Schalter mit 1–100 ganzen Prozentpunkten je Erledigung, auch je einzelner Wochen-Wiederholung (vom Nutzer bestätigt). Rücknahme zieht den tatsächlichen Beitrag ab, höchstens bis 0; die Erhöhung ist bei 100 gedeckelt. Zuordnungs-/Beitragsänderungen gelten sofort nur für neue Erledigungen. Bei einer Rücknahme nach Zuordnungswechsel wird das ursprünglich betroffene Zwischenziel korrigiert. Manuelle Fortschrittsänderungen bleiben möglich; spätere Rücknahmen ziehen den vorher gebuchten Beitrag vom dann aktuellen Stand ab. Pausiert/Außer Plan bleiben bei Fortschritt unter 100 erhalten; 100 setzt Erreicht, Rücknahme unter 100 stellt den vorherigen Status soweit konsistent wieder her. Der separate Ziel-erreicht-Schalter bleibt unabhängig. Archivierte Ziele erhalten keine neuen Beiträge, bestehende Beiträge bleiben rücknehmbar. Löschen löst Zuordnungen und erhält Todo-Stände. Frühere Aussagen zur vollständigen Unabhängigkeit sind damit ergänzt, die Verknüpfung bleibt optional.

Am 17.09.2026 ausdrücklich als nächster Schritt beauftragt: ein Todos-Tab mit Tages- und Wochenaufgaben (#13–#17). Damit wird die bisherige Zurückstellung der Routinen aufgehoben; Nutzererprobung #4 bleibt offen. Die folgenden kleinen Produktentscheidungen konkretisieren den ersten Stand und können nach Nutzung angepasst werden.

- Dritter Hauptbereich **Todos**, unabhängig von Zielen und deren Fortschritt. Android-Zurück führt von diesem Tab zuerst zu Ziele.
- Tagesaufgaben einmal abhaken oder rückgängig machen. Wochenaufgaben haben eine positive Zielanzahl von 1 bis 999; Plus/Minus zeigt beispielsweise „2 von 3 erledigt“. Überzählige Erledigungen sind nicht möglich.
- Tagesbeginn ist lokale Mitternacht; Wochen laufen Montag bis Sonntag. Kalenderdaten statt 24-Stunden-Dauern verhindern Verschiebungen durch Sommerzeit. Beispiel: Sonntag, 20.09.2026 → Montag, 21.09.2026 erzeugt neue Tages- und Wochenstände.
- Die lokale Gerätezeit gilt auch nach Zeitzonen- oder Uhrzeitänderung. Bei Rückkehr zu einem schon gespeicherten Zeitraum wird dessen Stand wiederverwendet. Es gibt keine vertrauenswürdige externe Uhr und keine Rekonstruktion tatsächlicher Aktivitätszeitpunkte.
- Aktuelle Stände entstehen beim Laden/Starten, Wiederaufnehmen nach Datumswechsel und spätestens 15 Sekunden nach einem Datumswechsel in der geöffneten App. Kein Hintergrunddienst. Mehrfaches Öffnen erzeugt keine Duplikate.
- Ausgelassene Zeiträume ohne App-Nutzung werden nicht nachträglich angelegt. Vorhandene Stände bleiben erhalten; Erledigungen werden niemals erfunden. Eine neue Vorlage erscheint sofort im aktuellen Zeitraum.
- Titel, Häufigkeit und Zielanzahl werden pro Zeitraum eingefroren. Bearbeitung ändert Titel/Zielanzahl ab dem nächsten neu angelegten Zeitraum; täglich/wöchentlich bleibt für eine Vorlage fest. Zum Wechsel eine neue Aufgabe anlegen und die bisherige beenden.
- **Aufgabe beenden** verlangt Bestätigung und stoppt künftige Wiederholungen. Der aktuelle Zeitraum bleibt abhakbar; seine Karte erklärt das Ende. Vorlage und alte Ergebnisse bleiben für Historie und Backup erhalten. Kein endgültiges Löschen von Historie in diesem Schritt.
- Am Ende des Tabs liegt **Vergangene Zeiträume**: eine nur lesbare Liste mit Zeitraum, damaligem Titel und Erledigungsstand. Bei zurückgestellter Gerätezeit können dort auch bereits gespeicherte spätere Daten erscheinen.
- Drei getrennte Bereiche im Code: Todo-Fachmodell, Datenzugriff und Oberfläche. Bestehende SQLite-Verbindung, Änderungssteuerung und Backup werden mitgenutzt.

## Einstellungen und Gestaltung · 17.09.2026

Der Auftrag, die App anhand der Referenz weiter zu vervollständigen, zieht #18 vor die noch offene mehrtägige Erprobung aus #4. Systemdarstellung ist der Ausgangspunkt; Hell- und Dunkelmodus lassen sich ausdrücklich wählen. Die Auswahl wird lokal gespeichert, wirkt unmittelbar auf alle Screens und bleibt nach Neustart erhalten. Farben und Komponenten sind zentral austauschbar; Status behält zusätzlich seine Textbeschriftung.

Das Zahnrad öffnet Einstellungen mit Darstellung, Datensicherung, Informationen zur lokalen Datenhaltung und Lizenzen. Nicht implementierte Sprachwahl, Benachrichtigungen und Erinnerungen erhalten keine funktionslosen Schalter. Alle Inhalte lassen sich nach ausdrücklicher Bestätigung atomar löschen; Darstellung und exportierte Dateien bleiben erhalten. Vorher wird auf eine Sicherung hingewiesen.

Ziele behalten kompakte Emoji-Karten als einfache Alternative zu eigenen Bildern. Eigene Zielbilder (#19) bleiben offen: konsistente Dateiverwaltung, Android-Auswahl, Größenbegrenzung und Backup müssen zusammen umgesetzt werden. Streak (#20) und Einführung (#21) warten weiterhin auf Nutzungsfeedback. Die drei bestehenden Hauptbereiche bleiben erhalten, Einstellungen sind von jedem Tab erreichbar.

### Konkretisierung der Referenzoberfläche · 17.09.2026

Auf Nutzerwunsch stehen Hell- und Dunkelmodus als zwei gleich breite Kästen nebeneinander; Systemdarstellung bleibt darunter wählbar. Sprache, Benachrichtigungen, Erinnerungen und Impressum sind ausdrücklich als „Platzhalter – noch nicht verfügbar“ sichtbar. Antippen erklärt den fehlenden Funktionsumfang; es werden keine Einstellungen vorgetäuscht. Das überschreibt die frühere Entscheidung gegen sichtbare Platzhalter.

Im Ziele-Tab bleibt das Archiv fest über der Hauptnavigation, während die Ziele separat scrollen. Der Zielkopf hat ein flaches, dekoratives Landschaftscover als austauschbaren Hintergrund. Der Emoji steht im Kreis neben dem Titel. Unter dem Titel stehen Frist und Fortschrittskreis; der zusätzliche Fortschrittsbalken und die doppelte Fristangabe wurden entfernt. Eigene Coverauswahl bleibt offen.

### Eigene Zielbilder und einzelnes Emoji · 17.09.2026

Der Nutzer beauftragt #19 ausdrücklich: Bildauswahl oben im Ziel-Editor, ersetzbar und entfernbar, als Cover im Zielkopf. Verkleinerte lokale Kopien werden mit dem Ziel und im Backup gespeichert. Der dekorative Hintergrund bleibt der Fallback ohne Bild; es gibt keine verpflichtende Auswahl. Das Emoji-Feld steht links neben dem Titel und akzeptiert einen Unicode-Graphemcluster statt eines einzelnen Codepoints, sodass etwa Hautfarben und Flaggen zusammenbleiben. Alte gespeicherte Emoji-Texte werden bei Migration und Backup nicht verändert; beim Bearbeiten wird nur das erste sichtbare Zeichen angeboten.

Das App-Icon zeigt nun die Silhouette eines meditierenden Mönchs mit angedeuteter Robe, als skalierbare Android-Vektorgrafik.
