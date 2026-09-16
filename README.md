# The Guide

Eine minimalistische App, die große Ziele in überschaubare Zwischenziele übersetzt und Fortschritt sichtbar macht. Android zuerst, iOS später; Desktop bleibt eine Option.

**Status:** Produktplanung, noch kein App-Code. **The Guide** ist der vorläufige App-Name und darf sich ändern. Das Repository heißt weiterhin **guided-notes**. Namen und Branding sind keine Voraussetzung für den technischen Start.

## Produktkern

Der ursprüngliche Vorschlag einer geführten Notizen-App wird durch die Ziele-Struktur konkretisiert. Der frühere Ansatz „eine Notiz, ein nächster Schritt“ ist keine verbindliche Vorgabe mehr. Ob freie Notizen zusätzlich sinnvoll sind, bleibt Teil der Produktplanung.

### Ziele

- Übersicht mit bis zu fünf großen Zielen als schlichten, abgerundeten Karten.
- Eine Plus-Karte erscheint unter den vorhandenen Zielen, solange die Grenze nicht erreicht ist; auch im leeren Zustand.
- Zielkarten öffnen die Zieldetails. Das Archiv steht unterhalb der Ziele.
- Eine Detailseite zeigt Name, Motivation („Warum?“), Fortschritt, Zeitdarstellung, Zwischenziele und Statusaktionen.
- Ein Zwischenziel in den Details führt direkt zum entsprechenden Eintrag auf der Zwischenziele-Seite.

Ob die Grenze nur aktive Ziele betrifft und wie erreichte Ziele, Archivieren, Wiederherstellen und Löschen zusammenhängen, wird vor der Umsetzung geklärt. Archivieren soll die zugehörigen Zwischenziele aus der aktiven Übersicht entfernen; Löschen ebenso, aber mit Schutz vor versehentlichem Datenverlust.

### Zwischenziele

- Beliebig viele Zwischenziele, nach ihrem großen Ziel gruppiert, mit einer leicht erreichbaren Hinzufügen-Aktion.
- Zugehörigkeit über den Namen des Ziels und ein gemeinsames Emoji erkennbar; Bilder sind eine spätere Gestaltungsoption.
- Fortschritt, Zeit und auswählbarer Status sind sichtbar. Statusänderung erfolgt über den jeweiligen Eintrag.
- Statusvorschlag aus dem Input: „Not started“, „On track“, „Off track / on hold“, optional „At risk“, „Achieved“. Bedeutung, deutsche Bezeichnungen und Abgrenzung werden noch entschieden.
- Statusfarben sind ergänzende Signale; Information muss auch ohne Farberkennung verständlich bleiben.

Fortschritt und verstrichene/verbleibende Zeit sind verschiedene Größen. Ihre Berechnung und Darstellung sind offen; die Beispielprozente im Referenzbild sind keine Datenmodell-Vorgabe.

### Spätere Ergänzung: Tages- und Wochenaufgaben

Eine zusätzliche Seite bietet zwei Bereiche für konfigurierbare Tages- und Wochenaufgaben. Tagesaufgaben lassen sich abhaken, Wochenaufgaben gegebenenfalls mehrfach bis zu einer Zielanzahl. Abgeschlossene Zeiträume bleiben im eigenen Archiv erhalten. Neue Tage bzw. Wochen beginnen mit frischen Erledigungsständen.

Vor der Umsetzung werden Tageswechsel, Wochenbeginn, Zeitzone, verpasste Zeiträume und Änderungen an Vorlagen geklärt. Ein Zurücksetzen darf alte Ergebnisse nicht überschreiben. Ein eigener Hintergrunddienst wird dadurch nicht automatisch erforderlich.

## Gestaltung

Ruhig, minimalistisch und möglichst selbsterklärend: wenig Text, klare Typografie, großzügiger Abstand und wenige eindeutige Aktionen. Die gewünschte Apple-artige Ruhe dient als Gestaltungsrichtung; Android-Bedienung, Zurück-Navigation, Lesbarkeit und ausreichend große Touch-Flächen bleiben wichtig.

Die Kopfzeile kann je nach Seite passende Aktionen zeigen: Einstellungen, Sprung zu einem Zielcluster oder Bearbeitung der Routinen. Konkrete Symbole und Navigation werden im Entwurf geprüft; ein Pinsel ist beispielsweise nur ein Vorschlag für „Bearbeiten“.

Die [UI-Referenz](docs/reference/ui-inspiration.png) ist eine Inspiration aus dem bereitgestellten Kollegen-Input, kein fertiges Design und keine verbindliche Spezifikation. Begrüßungsblöcke, Fotos, Farben, doppelte Fortschrittsanzeigen und zusätzliche Einstellungen müssen nicht übernommen werden. Funktionen, die nur das Bild ergänzt (z. B. Benachrichtigungen oder Spracheinstellungen), sind dadurch nicht beauftragt.

Hell-/Dunkelmodus, Zielbilder und optionale Streaks liegen im späteren Backlog. Ein Tutorial wird nur bei beobachtetem Erklärungsbedarf erwogen; zunächst soll der Kernablauf selbst verständlich sein.

## Technische Richtung

| Bereich | Startpunkt |
| --- | --- |
| App | Flutter und Dart; zunächst Android |
| Speicherung | Offline und ohne Konto, SQLite mit Drift als bevorzugter Ansatz |
| Aufbau | Kleine Module nach Funktionen, zusätzliche Schichten bei konkretem Bedarf |
| State/Navigation | Flutter-Bordmittel; weitere Pakete nur begründet |
| Qualität | Formatierung, Analyse, gezielte Tests und Android-Build ab dem Grundgerüst |
| Zusammenarbeit | Ein Repository, GitHub Issues, kurze Branches, Pull Requests |

Flutter unterstützt die später gewünschten Plattformen; Plugins und Bedienung müssen je Plattform geprüft werden. iOS-Builds benötigen macOS und Xcode. SDK- und Paketversionen werden bei der Einrichtung geprüft und dokumentiert. Quellen: [Flutter-Plattformen](https://docs.flutter.dev/reference/supported-platforms), [Plattformeinrichtung](https://docs.flutter.dev/platform-integration), [Drift](https://drift.simonbinder.eu/).

Das Datenmodell folgt den geklärten Regeln für Ziele und Zwischenziele. Es erhält stabile IDs, eindeutige Beziehungen und notwendige Zeitangaben. Wiederkehrende Aufgaben bekommen erst mit ihrer Umsetzung Vorlagen und getrennte Zeitraumergebnisse. Keine allgemeine Ereignis- oder Sync-Architektur auf Vorrat.

Cloud, Accounts, KI, Kalender, Zusammenarbeit und Desktop gehören nicht zum aktuellen Kernumfang. Ein Export mit geprüfter Wiederherstellung ist vor der Nutzung mit wichtigen eigenen Daten erforderlich; lokale Speicherung allein ist kein Backup.

## Planung und Reihenfolge

Der aktuelle Aufgabenstatus und konkrete Akzeptanzkriterien stehen ausschließlich in den [GitHub Issues](https://github.com/anurag-cibo/guided-notes/issues). Kategorien beschreiben die Art der Arbeit; Prioritäten beschreiben ihre Reihenfolge:

| Kategorien | Bedeutung |
| --- | --- |
| `typ:technik` | Projektbasis, Speicherung, technische Qualität |
| `typ:planung` | Produktregeln, UX-Entscheidungen, Auswertung |
| `typ:feature` | Nutzerfunktionen mit User Story |

| Priorität | Bedeutung |
| --- | --- |
| `prio:P0` | Jetzt: technische Basis und notwendige Produkt-/UX-Planung, gleichrangig |
| `prio:P1` | Danach: Kernablauf und Voraussetzungen für verlässliche Eigennutzung |
| `prio:P2` | Später: Routinen und weitere Ergänzungen; noch keine Umsetzungszusage |

Jedes aktive Issue erhält genau eine Kategorie und eine Priorität. Abhängigkeiten im Issue gehen der Reihenfolge nach Nummer vor. Die technische Einrichtung kann beginnen, während Produktregeln geklärt werden; Datenmodell und fachliche Features warten auf ihre jeweiligen Entscheidungen. Ein zusätzliches Projektboard ist vorerst nicht nötig.

## Entwicklung starten

Die [AGENTS.md](AGENTS.md) beschreibt den Workflow. Noch existiert kein Flutter-Projekt und damit kein ausführbarer App-Build. Setup, SDK-Version und überprüfte Befehle werden mit dem Grundgerüst ergänzt. Der aktuelle Auftrag umfasst Dokumentation und Backlog, keine App-Implementierung.
