# Familienkalender — Verbesserungsvorschlaege

Letzte Aktualisierung: 2026-03-23

---

## Legende

| Prioritaet | Bedeutung |
|------------|-----------|
| 🔴 Hoch | Sicherheit, Stabilitaet oder stark eingeschraenkte Nutzbarkeit |
| 🟡 Mittel | Spuerbare Verbesserung fuer den Alltag |
| 🟢 Nice-to-have | Komfort, Aesthetik, Zukunftssicherheit |

| Aufwand | Bedeutung |
|---------|-----------|
| S | Wenige Stunden, einzelne Datei |
| M | 1-2 Tage, mehrere Dateien |
| L | Mehrere Tage, architekturelle Aenderungen |

---

## 1. Sicherheit & Infrastruktur

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 1.1 | **CORS einschraenken** | 🔴 | S | `allow_origins=["*"]` auf tatsaechliche Domains beschraenken (z.B. NAS-IP, localhost). Aktuell fuer Produktion unsicher. |
| 1.2 | **Refresh-Token einfuehren** | 🔴 | M | Aktuell nur Access-Token (24h). Refresh-Token mit kuerzerer Access-Lifetime (15min) + automatischer Erneuerung. |
| 1.3 | **Rate Limiting** | 🟡 | S | Insbesondere fuer `/api/auth/login` und `/api/ai/generate-meal-plan` (Claude API Kosten). z.B. `slowapi` Library. |
| 1.4 | **HTTPS erzwingen** | 🟡 | S | Reverse-Proxy-Konfiguration (Synology) oder HSTS-Header. JWTs gehen aktuell ueber HTTP. |
| 1.5 | **API-Key Rotation fuer Anthropic** | 🟢 | S | Hinweis in Doku/Settings, wenn Key aelter als X Tage. Kein technischer Blocker, aber Best Practice. |

---

## 2. Feature-Paritaet Android ↔ Web

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 2.1 | **KI-Essensplanung in Android** | 🟡 | L | Kompletter AI-Dialog (Slot-Auswahl, Preview, Confirm, Undo) fehlt in der Android-App. API-Endpunkte existieren bereits. |
| 2.2 | **Knuspr-Integration in Android** | 🟢 | M | APIs existieren. Android-UI fuer Produktsuche, Warenkorb, Lieferslots fehlt. |
| 2.3 | **Quick-Add fuer Todos in Android** | 🟡 | S | Web hat Schnelleingabe-Leiste. Android nur FAB → volles Formular. |
| 2.4 | **Mitglieder-Filter fuer Todos in Android** | 🟢 | S | Web hat Filter nach Mitglied. Android nur nach Prioritaet. |
| 2.5 | **Kategorie-Verwaltung in UI** | 🟡 | M | API fuer CRUD existiert, aber weder Web noch Android haben eine UI dafuer. Aktuell nur Default-Seed. |
| 2.6 | **Kochhistorie im Web anzeigen** | 🟢 | S | Android zeigt History pro Rezept. Web-Frontend fehlt dieses Feature. API existiert. |
| 2.7 | **Rezeptvorschlaege im Web** | 🟢 | S | `GET /api/recipes/suggestions` existiert. Web-Frontend nutzt es nicht. |
| 2.8 | **Cookidoo-Kalender im Web** | 🟢 | S | `GET /api/cookidoo/calendar` existiert. Kein Web-UI dafuer. |

---

## 3. UX-Verbesserungen Web-Frontend

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 3.1 | **Drag & Drop im Wochenplan** | 🟡 | M | Rezepte zwischen Slots verschieben per Drag & Drop statt "Leeren + Neu zuweisen". |
| 3.2 | **Wochenansicht im Kalender** | 🟡 | M | Nur Monatsansicht vorhanden. Android hat 4 Ansichten. Mindestens Woche waere hilfreich. |
| 3.3 | **Rezeptsuche / Filterung** | 🟡 | S | Rezeptliste hat keine Suche oder Filter (Schwierigkeit, Zubereitungszeit, Zutaten). Android hat Suchfeld. |
| 3.4 | **Toast-Benachrichtigungen statt alert()** | 🟡 | S | `alert()` und `confirm()` durch nicht-blockierende Toast-Notifications ersetzen. |
| 3.5 | **Dark Mode** | 🟢 | M | CSS-Variablen sind schon vorbereitet. `prefers-color-scheme` Media Query + Toggle. |
| 3.6 | **Kalender: Event-Farben nach Kategorie** | 🟢 | S | Farben existieren im Backend. Events im Kalender koennten farbkodiert sein (wie im Day-Panel, aber auch im Grid). |
| 3.7 | **Keyboard-Shortcuts** | 🟢 | S | z.B. `N` fuer neues Event, `T` fuer neues Todo, Pfeiltasten fuer Kalender-Navigation. |
| 3.8 | **Loading-Skeleton statt leerem Zustand** | 🟢 | S | Skeleton-Placeholder waehrend Daten laden statt leere Bereiche. |

---

## 4. UX-Verbesserungen Android

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 4.1 | **Pull-to-Refresh** | 🟡 | S | Aktuell kein manueller Refresh-Mechanismus ausser Tab-Wechsel. |
| 4.2 | **Push-Benachrichtigungen** | 🟡 | L | Bei neuen Terminvorschlaegen, faelligen Todos oder Aenderungen durch andere Mitglieder. Benoetigt Backend-Websocket oder FCM. |
| 4.3 | **Widget fuer Homescreen** | 🟢 | M | Tagesagenda oder naechstes Essen als Android-Widget. |
| 4.4 | **Offline-Feedback verbessern** | 🟢 | S | Klarer anzeigen welche Aenderungen in der Queue sind und wann zuletzt synchronisiert wurde. |

---

## 5. KI-Erweiterungen

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 5.1 | **Ernaehrungspraeferenzen persistent speichern** | 🟡 | M | Aktuell muss man "vegetarisch" etc. jedes Mal neu eingeben. Pro-Familie-Einstellungen speichern. |
| 5.2 | **KI-Einkaufslisten-Optimierung** | 🟡 | M | Claude koennte Einkaufslisten nach Supermarkt-Gang sortieren oder Mengen zusammenfassen. |
| 5.3 | **Rezept-Generierung per KI** | 🟢 | M | "Ich habe folgende Zutaten: ..." → Claude schlaegt Rezept vor und erstellt es direkt. |
| 5.4 | **Essensplan-Bewertung** | 🟢 | S | Nach einer Woche: "Wie war der KI-Plan?" Feedback zurueck an Claude fuer bessere kuenftige Vorschlaege. |
| 5.5 | **Saisonale / regionale Vorschlaege** | 🟢 | S | Aktuelles Datum und Region im Prompt beruecksichtigen (z.B. Spargelsaison, Weihnachtszeit). |
| 5.6 | **Budget-Limit fuer Essensplanung** | 🟢 | M | Ungefaehre Kosten pro Rezept + Gesamtbudget als Constraint fuer Claude. |
| 5.7 | **Claude-Modell konfigurierbar machen** | 🟢 | S | Aktuell hardcoded `claude-sonnet-4-20250514`. In Config auslagern fuer Flexibilitaet. |

---

## 6. Daten & Backend

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 6.1 | **Alembic-Migrationen aktivieren** | 🔴 | M | Schema-Aenderungen erfordern aktuell DB-Loesung. Alembic ist konfiguriert aber hat keine Versionen. Erste Migration aus bestehendem Schema generieren. |
| 6.2 | **Automatisierte Tests** | 🔴 | L | Keine Tests vorhanden. Mindestens API-Integration-Tests mit pytest + httpx. Kritische Pfade: Auth, Meal-Plan, AI-Preview. |
| 6.3 | **Backup-Mechanismus** | 🟡 | S | SQLite-DB automatisch sichern (Cron/Docker-Volume-Backup). Ein Datenverlust ist aktuell nicht wiederherstellbar. |
| 6.4 | **PostgreSQL-Option** | 🟢 | M | SQLAlchemy macht den Switch einfach. PostgreSQL wuerde Concurrent Writes und bessere Skalierung ermoeglichen. |
| 6.5 | **Rezeptbilder lokal speichern** | 🟡 | M | `image_url` zeigt auf externe Cookidoo-URLs. Wenn Cookidoo-Session ablaeuft, sind Bilder weg. Lokal cachen. |
| 6.6 | **API-Versionierung** | 🟢 | M | Alle Endpunkte unter `/api/` ohne Versionierung. Bei Breaking Changes problematisch fuer Android-App. |
| 6.7 | **Structured Logging** | 🟢 | S | Aktuell einfaches `logging`-Modul. JSON-Logging fuer bessere Auswertung (z.B. mit structlog). |
| 6.8 | **Mehrere Familien / Haushalte** | 🟢 | L | Aktuell gibt es nur einen globalen Datenbestand. Multi-Tenancy wuerde mehrere Familien auf einer Instanz ermoeglichen. |

---

## 7. Integrationen

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 7.1 | **CalDAV-Sync** | 🟡 | L | Kalender-Events mit Standard-Kalender-Apps synchronisieren (Google Calendar, Apple Calendar, Nextcloud). |
| 7.2 | **Knuspr Web-UI** | 🟡 | M | Produkte suchen, Warenkorb verwalten, Lieferslots auswaehlen — aktuell nur ueber MCP nutzbar. |
| 7.3 | **Weitere Supermaerkte** | 🟢 | L | REWE, Amazon Fresh, Flink als Alternative zu Knuspr. Plugin-Architektur fuer Supermarkt-Bridges. |
| 7.4 | **Import aus anderen Rezeptquellen** | 🟢 | M | Chefkoch.de, Eat This, eigene URLs scrapen. Aktuell nur Cookidoo. |
| 7.5 | **Telegram/WhatsApp Bot** | 🟢 | M | "Was gibt's heute zum Essen?" per Messenger. Nutzt bestehende API. |
| 7.6 | **iCal-Feed Export** | 🟢 | S | Oeffentlicher `.ics`-Feed fuer Events, der in anderen Kalender-Apps abonniert werden kann. |

---

## 8. Performance & DevOps

| # | Vorschlag | Prio | Aufwand | Details |
|---|-----------|------|---------|---------|
| 8.1 | **Frontend-Bundling** | 🟢 | M | Vanilla JS funktioniert, aber kein Minification, kein Tree-Shaking, kein Bundling. Vite oder esbuild wuerde Ladezeiten verbessern. |
| 8.2 | **Service Worker / PWA** | 🟡 | M | Web-App als PWA installierbar machen mit Offline-Cache fuer statische Assets. |
| 8.3 | **Health-Check Endpoint** | 🟡 | S | `GET /api/health` fuer Docker Health-Checks und Monitoring. |
| 8.4 | **CI/CD Pipeline** | 🟡 | M | Automatisches Testen und Deployment bei Push. GitHub Actions oder Gitea Actions. |
| 8.5 | **Docker Multi-Stage Build** | 🟢 | S | Kleinere Images durch Multi-Stage Build (aktuell einfaches `python:3.12-slim`). |
| 8.6 | **Caching fuer Cookidoo-Daten** | 🟡 | S | Collections aendern sich selten. Redis oder In-Memory-Cache mit TTL statt bei jedem Aufruf neu laden. |

---

## 9. Priorisierte Roadmap-Empfehlung

### Phase 1 — Stabilitaet (1-2 Wochen)
1. **6.1** Alembic-Migrationen aktivieren
2. **1.1** CORS einschraenken
3. **6.2** Erste API-Tests schreiben (Auth, Meals, AI)
4. **6.3** SQLite-Backup einrichten
5. **8.3** Health-Check Endpoint

### Phase 2 — Nutzererlebnis (2-4 Wochen)
6. **3.3** Rezeptsuche im Web
7. **3.4** Toast-Benachrichtigungen
8. **2.5** Kategorie-Verwaltung in UI
9. **5.1** Ernaehrungspraeferenzen persistent speichern
10. **2.1** KI-Essensplanung in Android

### Phase 3 — Erweiterungen (4-8 Wochen)
11. **3.2** Wochenansicht im Web-Kalender
12. **8.2** PWA / Service Worker
13. **7.1** CalDAV-Sync
14. **5.3** Rezept-Generierung per KI
15. **7.2** Knuspr Web-UI
