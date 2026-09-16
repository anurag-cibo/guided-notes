# Guided Notes

Eine kleine, geführte Notizen-App: Gedanken festhalten, einen nächsten Schritt wählen und den eigenen Fortschritt nachvollziehen. Android zuerst; iOS später, Desktop optional.

**Status:** Projektvorbereitung. Dieses Repository enthält zunächst Produktumfang und Arbeitsregeln, noch keine ausführbare App. „Guided Notes“ ist ein Arbeitsname. Der folgende Ablauf ist ein Vorschlag zur Erprobung, keine bereits validierte Produktanforderung.

## Die erste Version

Wir prüfen eine einfache Hypothese: Wenige freiwillige Leitfragen helfen dabei, aus einer Notiz eine konkrete Handlung zu machen, ohne zusätzlichen Verwaltungsaufwand zu erzeugen.

1. Eine Textnotiz erstellen, bearbeiten und wiederfinden.
2. Optional beantworten: „Was beschäftigt mich?“ und „Was ist mein nächster kleiner Schritt?“
3. Höchstens einen nächsten Schritt pro Notiz festhalten und als erledigt markieren; das lässt sich rückgängig machen.
4. In einer schlichten Übersicht sehen, welche Schritte offen oder erledigt sind. Keine Bewertung der persönlichen Produktivität.

Alles funktioniert offline und ohne Konto. Eine normale, ungeführte Notiz bleibt jederzeit möglich.

### Wann der erste Prototyp seinen Zweck erfüllt

- Eine Notiz samt nächstem Schritt bleibt nach einem vollständigen App-Neustart erhalten.
- Erstellen, Bearbeiten, Löschen und Erledigen funktionieren im Flugmodus; Fehler beim Speichern sind sichtbar.
- Versehentliches Löschen ist durch Rückfrage oder Rückgängig-Funktion abgesichert.
- Der Ablauf wird mehrere Tage mit eigenen Beispielen ausprobiert. Entscheidend ist, ob die Führung hilft oder stört; weitere Funktionen folgen erst aus diesem Feedback.

Vor der Umsetzung klären wir anhand von drei echten Beispielen, was „geführt“ konkret bedeuten soll: Tagesreflexion, Projektfortschritt oder etwas anderes. Der vorgeschlagene Ablauf darf dadurch noch kleiner werden.

## Bewusst später

Accounts, Cloud-Synchronisierung, KI-Funktionen, Erinnerungen, Kalender, Fokus-Timer, Gewohnheiten, Streaks, komplexe Statistiken, Zusammenarbeit und Desktop sind kein Bestandteil der ersten Version. Ein Backend-Anbieter wird noch nicht festgelegt.

Bevor die App für wichtige echte Notizen genutzt wird, brauchen wir einen einfachen Export und einen geprüften Weg zur Wiederherstellung. Lokale Speicherung allein ist kein Backup.

## Technische Richtung

| Bereich | Startpunkt |
| --- | --- |
| App | Flutter und Dart; zunächst nur Android einrichten |
| Daten | Lokal auf dem Gerät; SQLite mit Drift als bevorzugter Ansatz beim ersten Speicherschritt |
| Aufbau | Kleine Dateien nach Funktionen gruppieren; zusätzliche Schichten erst bei konkretem Bedarf |
| State und Navigation | Zunächst Flutter-Bordmittel; Riverpod bzw. go_router erst bei nachgewiesenem Bedarf |
| Zusammenarbeit | Ein GitHub-Repository, Issues, kurze Branches und Pull Requests |

Flutter unterstützt die später gewünschten Plattformen. Trotzdem müssen Oberfläche und Plugins pro Plattform geprüft werden; iOS-Builds benötigen macOS und Xcode. Drift bietet relationale Speicherung für Dart/Flutter. Versionen und konkrete Abhängigkeiten werden beim Implementierungsstart geprüft und festgehalten.

Quellen: [Flutter-Plattformen](https://docs.flutter.dev/reference/supported-platforms), [Plattformeinrichtung](https://docs.flutter.dev/platform-integration), [Drift](https://drift.simonbinder.eu/).

### Datenmodell: nur das heute Benötigte

Als Ausgangspunkt genügt eine Notiz mit ID, Text, optionalem nächstem Schritt, Erledigt-Zeitpunkt sowie Erstellungs- und Änderungszeitpunkt. Dauerhafte IDs und eindeutig behandelte Zeitangaben sind sinnvoll. Fortschritt wird zunächst direkt aus den gespeicherten Schritten abgeleitet.

Keine vorsorglichen Sync-Felder, Löschmarkierungen oder allgemeine Ereignistabelle. Wenn später eine echte Verlaufsauswertung benötigt wird, entscheiden wir anhand ihrer Anforderungen über ein zusätzliches Datenmodell. Datenbankänderungen müssen vorhandene Notizen erhalten und durch Migrationen abgesichert werden.

## Arbeiten im Repository

Die verbindlichen Arbeitsregeln stehen in [AGENTS.md](AGENTS.md). Eine zusätzliche PROJECT.md wäre momentan eine zweite Kopie derselben Informationen.

- README: Produktumfang und aktuelle technische Richtung.
- AGENTS.md: Workflow für Menschen und Coding-Agenten.
- GitHub Issues: Aufgaben, Akzeptanzkriterien und offene Entscheidungen.
- Pull Requests: Umsetzung, Prüfung und Bezug zum Issue.

Ein separates GitHub Project, ADR-Verzeichnis oder detailliertes Prioritätssystem ist zum Start nicht erforderlich.

## Nächste kleine Schritte

Diese Liste beschreibt die Reihenfolge, keinen parallel gepflegten Aufgabenstatus. Sobald GitHub verfügbar ist, liegen die konkreten Aufgaben in Issues.

1. **Kernablauf klären:** Drei reale Notizen und den gewünschten Nutzen der Führung beschreiben; ein Beispiel als Prototyp auswählen.
2. **Android-Grundgerüst:** Flutter einrichten, SDK-Version dokumentieren, App auf Gerät oder Emulator starten und minimale CI ergänzen.
3. **Notiz dauerhaft speichern:** Eine Notiz offline erstellen, bearbeiten, wieder öffnen und geschützt löschen; Fehler und Neustart prüfen.
4. **Führung und Fortschritt erproben:** Optionalen nächsten Schritt ergänzen, Erledigen/Rückgängig anbieten, einfache Übersicht testen.

## Entwicklung starten

Es gibt noch kein Flutter-Projekt und damit noch keine ausführbaren Build- oder Testbefehle. Beim Grundgerüst werden Setup, SDK-Version und tatsächliche Befehle hier ergänzt. Bis dahin werden ausschließlich Dokumentation und Projektorganisation geändert.
