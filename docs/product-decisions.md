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
