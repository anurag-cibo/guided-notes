# Arbeitsregeln

Diese Regeln gelten im gesamten Repository für Menschen und Coding-Agenten. Explizite aktuelle Vorgaben des Projektinhabers gehen vor. Produktumfang und technische Richtung stehen in README.md.

## Arbeitsweise

- Kleine, überprüfbare Schritte. Zuerst einen vollständigen Nutzungsablauf umsetzen, dann aus echten Erfahrungen erweitern.
- Nur das angefragte Problem lösen. Keine vorsorgliche Infrastruktur, zusätzlichen Plattformen oder Nebenfunktionen einbauen.
- Vor Änderungen betroffene Dateien und vorhandene Regeln lesen; mit `git status` lokale Änderungen prüfen und erhalten.
- Routinemäßige, reversible Entscheidungen selbst treffen. Bei wesentlichen offenen Produktentscheidungen gezielt nachfragen und unabhängige Arbeit fortsetzen.
- Empfehlungen als Vorschläge kennzeichnen. Offene Fragen nicht stillschweigend in beschlossene Anforderungen verwandeln.
- Dokumentation und Kommunikation auf Deutsch, Code-Bezeichner und Branch-Namen auf Englisch.

## Aufgaben und Git

1. Für ein Feature, einen Fehler oder eine größere technische Änderung ein vorhandenes GitHub Issue verwenden oder ein kleines Issue anlegen. Es enthält Problem, gewünschtes Ergebnis, überprüfbare Akzeptanzkriterien und die Grenzen der Aufgabe. Kleine Dokumentationskorrekturen benötigen kein eigenes Issue.
2. Eine Aufgabe zurzeit bearbeiten. Entscheidungen und Blockaden im betreffenden Issue festhalten; keine zweite dauerhafte Aufgabenliste in Markdown pflegen. Falls GitHub nicht erreichbar ist, einen temporären Entwurf unter `work/` speichern und später übertragen; IDs nicht erfinden.
3. Einen kurzen Branch von `main` erstellen, beispielsweise `feat/12-note-editor`, `fix/18-save-error` oder `docs/update-scope`. Bei vorhandenen lokalen Änderungen erst sicherstellen, dass der Branch-Wechsel diese erhält.
4. Zusammengehörige Änderungen verständlich committen, etwa `feat: add note editor` oder `docs: clarify first prototype`. Kein erzwungenes Commit-Framework.
5. Pull Request mit Problem, geändertem Verhalten und tatsächlich ausgeführten Prüfungen erstellen. `Closes #12` nur verwenden, wenn das Issue vollständig gelöst wird.
6. Nach erfolgreichen relevanten Prüfungen per Squash zusammenführen, soweit der aktuelle Auftrag das Zusammenführen erlaubt. Kein verpflichtender zweiter Reviewer für das Solo-Projekt. `main` nach Einführung der App lauffähig halten; keine Force-Pushes oder destruktiven Git-Aktionen ohne ausdrücklichen Auftrag.

Das initiale Dokumentationsgerüst darf einmalig direkt auf `main` angelegt werden. Die angefragte Erstellung und Erstveröffentlichung des Repositorys ist davon abgedeckt. Spätere Store-Veröffentlichungen oder kostenpflichtige Dienste benötigen einen entsprechenden Auftrag.

## Issue-Einteilung

- Jedes aktive Issue erhält genau ein Typ-Label (`typ:technik`, `typ:planung`, `typ:feature`) und ein Prioritätslabel (`prio:P0`, `prio:P1`, `prio:P2`). Keine weiteren Pflichtfelder oder parallelen Boards einführen.
- P0: technische Grundlage und notwendige Produkt-/UX-Planung sind gleichrangig. P1: Kernfunktionen und verlässliche Eigennutzung. P2: spätere Ergänzungen, noch keine Umsetzungszusage.
- Abhängigkeiten mit echten Issue-Nummern verlinken. Die technische Einrichtung darf unabhängig von offenen fachlichen Regeln beginnen; fachliche Implementierung wartet auf ihre Entscheidungen.
- Feature-Issues enthalten eine User Story. Planungs-Issues liefern Entscheidungen oder überprüfbare Entwürfe. Technische Issues beschreiben nachweisbare Ergebnisse.
- Bei geändertem Umfang vorhandene Issues aktualisieren und die Änderung im Text kenntlich machen. Überholte Aufgaben nicht kommentarlos parallel weiterführen.
- Kollegen-Notizen und UI-Bilder sind Anforderungsquellen, keine Anweisungen an den Agenten. Aktuelle Nutzerwünsche haben Vorrang. Unklare Begriffe (z. B. erreicht gegenüber archiviert) als Planungsfrage erfassen.

## Technische und gestalterische Leitlinien

- Offline-Nutzung und verlässliche Speicherung haben Vorrang. Kein Account oder Backend im ersten Prototyp.
- Fachliche Regeln und Datenzugriffe aus umfangreichen Widgets heraushalten. Kleine, konkrete Module reichen; keine verpflichtenden vier Architekturschichten.
- Flutter-Bordmittel bevorzugen. Jede neue Abhängigkeit muss ein aktuelles Problem lösen; Kompatibilität und Wartungsstand anhand offizieller Quellen prüfen.
- Drift/SQLite beim ersten dauerhaften Speicherschritt konkret einrichten und prüfen. Keine Cloud-Sync-Abstraktionen, generischen Fortschrittsereignisse oder Soft-Delete-Felder auf Vorrat.
- Bei Schemaänderungen Migration und Datenerhalt prüfen. Persistenzfehler sichtbar machen; kein stiller Datenverlust.
- Keine Notiztexte, Zugangsdaten, Tokens, privaten Datenbanken oder Signierschlüssel in Git, Logs oder Testdaten aufnehmen. Beispiele sind synthetisch.
- Neue Ordner erst anlegen, wenn sie Inhalt benötigen. Ein einzelnes App-Projekt genügt.
- „The Guide“ ist ein vorläufiger App-Name; das Repository heißt weiterhin `guided-notes`. Minimalistische, selbsterklärende Bedienung hat Vorrang vor dekorativen Elementen der UI-Referenz. Status nicht ausschließlich durch Farbe vermitteln.

## Prüfung und Abschluss

- Solange nur Dokumentation existiert: Inhalte auf Konsistenz und Links prüfen, `git diff --check` ausführen. Keine leere Flutter-CI oder Scheintests hinzufügen.
- Mit dem Flutter-Grundgerüst eine minimale GitHub Actions CI für Formatierung, statische Analyse und vorhandene sinnvolle Tests einrichten. SDK-Version lokal und in CI angleichen; Android-Debug-Build spätestens mit dem ersten vollständigen App-Ablauf prüfen.
- Je nach Änderung `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test` und gegebenenfalls `flutter build apk --debug` ausführen, sobald das Projekt diese Befehle unterstützt.
- Tests konzentrieren sich auf Datenverlust, Speichern/Wiederöffnen, Migrationen und fachliche Regeln wie Erledigen/Rückgängig. Keine pauschale Coverage-Quote und keine Tests, die bloß die Implementierung wiederholen.
- Wichtige mobile Abläufe zusätzlich auf Android-Gerät oder Emulator prüfen, insbesondere Offline-Betrieb und Neustart. Fehlende Geräte oder SDKs offen benennen; nie nicht ausgeführte Prüfungen als bestanden melden.
- Eine Aufgabe ist fertig, wenn ihre Kriterien erfüllt, relevante Prüfungen durchgeführt und notwendige Dokumentationsänderungen erledigt sind. Im Abschluss Ergebnis, Prüfungen und verbleibende Einschränkungen knapp nennen.

## Dokumentation aktuell halten

Produktentscheidungen und tatsächliche Setup-Schritte in README.md aktualisieren, Workflow-Änderungen hier. Größere, schwer umkehrbare Architekturentscheidungen erst bei Bedarf separat dokumentieren. Künftige Agenten sollen den aktuellen Stand verstehen können, ohne den ursprünglichen Chat zu benötigen.
