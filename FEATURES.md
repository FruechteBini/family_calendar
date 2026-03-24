# Familienkalender — Funktionsuebersicht

Letzte Aktualisierung: 2026-03-24

---

## Plattform-Uebersicht

| Plattform | Technologie | Pfad |
|-----------|-------------|------|
| **Backend API** | Python 3.12, FastAPI, SQLAlchemy, PostgreSQL | `backend/app/` |
| **Web-Frontend** | Vanilla JS SPA, CSS | `backend/app/static/` |
| **Android App** | Kotlin, Jetpack Compose, Room, Retrofit | `android/` |
| **MCP-Server** | Python, FastMCP SDK | `backend/mcp_server.py` |

---

## 1. Authentifizierung & Benutzerverwaltung

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Registrierung | ✅ | ✅ | – | `POST /api/auth/register` |
| Login (JWT) | ✅ | ✅ | – | `POST /api/auth/login` |
| Aktuellen User abfragen | ✅ | ✅ | – | `GET /api/auth/me` |
| User mit Familienmitglied verknuepfen | ✅ | ✅* | – | `PATCH /api/auth/link-member` |
| Familie erstellen | –* | – | – | `POST /api/auth/family` |
| Familie beitreten (Einladungscode) | –* | – | – | `POST /api/auth/family/join` |
| Aktuelle Familie abfragen | –* | – | – | `GET /api/auth/family` |
| Logout | ✅ | ✅ | – | Frontend-only (Token loeschen) |
| Server-URL konfigurieren | – | ✅ | – | – |

\* Android: API vorhanden, UI nicht exponiert
\* Familie: API vorhanden, Web/Android-UI muss noch implementiert werden. User muss einer Familie beitreten bevor andere Endpunkte nutzbar sind.

---

## 2. Kalender / Termine

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Monatsansicht | ✅ | ✅ | – | `GET /api/events/` |
| Wochenansicht | – | ✅ | – | `GET /api/events/` |
| 3-Tage-Ansicht | – | ✅ | – | `GET /api/events/` |
| Tagesansicht | – | ✅ | – | `GET /api/events/` |
| Tages-Detail-Panel | ✅ | ✅ | – | – |
| Event erstellen | ✅ | ✅ | ✅ | `POST /api/events/` |
| Event bearbeiten | ✅ | ✅ | ✅ | `PUT /api/events/{id}` |
| Event loeschen | ✅ | ✅ | ✅ | `DELETE /api/events/{id}` |
| Ganztaegige Events | ✅ | ✅ | ✅ | – |
| Kategorie zuweisen | ✅ | ✅ | ✅ | – |
| Mitglieder zuweisen | ✅ | ✅ | ✅ | – |
| Agenda (Events + Todos) | – | – | ✅ | – |
| Heute / Diese Woche (Resource) | – | – | ✅ | `calendar://today`, `calendar://week` |

---

## 3. Aufgaben (Todos)

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Todos auflisten mit Filtern | ✅ | ✅ | ✅ | `GET /api/todos/` |
| Schnelleingabe (Quick-Add) | ✅ | – | – | `POST /api/todos/` |
| Todo erstellen (volles Formular) | ✅ | ✅ | ✅ | `POST /api/todos/` |
| Todo bearbeiten | ✅ | ✅ | – | `PUT /api/todos/{id}` |
| Todo loeschen | ✅ | ✅ | ✅ | `DELETE /api/todos/{id}` |
| Todo abschliessen / oeffnen | ✅ | ✅ | ✅ | `PATCH /api/todos/{id}/complete` |
| Sub-Todos (Unteraufgaben) | ✅ | ✅ | – | `POST /api/todos/` (mit parent_id) |
| Filter: Prioritaet | ✅ | ✅ | ✅ | Query-Parameter |
| Filter: Mitglied | ✅ | – | ✅ | Query-Parameter |
| Filter: Erledigte ein/ausblenden | ✅ | ✅ | ✅ | Query-Parameter |
| Todo mit Event verknuepfen | ✅ | ✅ | ✅ | `PATCH /api/todos/{id}/link-event` |
| Mehrpersonen-Markierung | ✅ | ✅ | – | `requires_multiple` Feld |
| Offene Todos nach Kategorie | – | – | ✅ | `todos://open`, `todos://high-priority` |

---

## 4. Terminvorschlaege (Proposals)

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Terminvorschlag erstellen | ✅ | ✅ | – | `POST /api/todos/{id}/proposals` |
| Vorschlaege fuer Todo auflisten | ✅ | ✅ | – | `GET /api/todos/{id}/proposals` |
| Vorschlag annehmen / ablehnen | ✅ | ✅ | – | `POST /api/proposals/{id}/respond` |
| Gegenvorschlag senden | ✅ | ✅ | – | `POST /api/proposals/{id}/respond` |
| Offene Vorschlaege anzeigen | ✅ | ✅ | – | `GET /api/proposals/pending` |
| Badge-Zaehler offener Vorschlaege | ✅ | ✅ | – | – |

---

## 5. Familienmitglieder

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Mitglieder auflisten | ✅ | ✅ | – | `GET /api/family-members/` |
| Mitglied erstellen | ✅ | ✅ | – | `POST /api/family-members/` |
| Mitglied bearbeiten | ✅ | ✅ | – | `PUT /api/family-members/{id}` |
| Mitglied loeschen | ✅ | ✅ | – | `DELETE /api/family-members/{id}` |
| Avatar (Emoji + Farbe) | ✅ | ✅ | – | – |

---

## 6. Kategorien

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Kategorien auflisten | ✅ | ✅ | – | `GET /api/categories/` |
| Kategorie erstellen | –* | – | – | `POST /api/categories/` |
| Kategorie bearbeiten | –* | – | – | `PUT /api/categories/{id}` |
| Kategorie loeschen | –* | – | – | `DELETE /api/categories/{id}` |

\* API existiert, Web-UI und Android-UI nicht vorhanden. Default-Kategorien werden automatisch beim Erstellen einer neuen Familie geseedet.

---

## 7. Rezepte

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Rezepte auflisten | ✅ | ✅ | ✅ | `GET /api/recipes/` |
| Rezept erstellen (mit Zutaten) | ✅ | ✅ | – | `POST /api/recipes/` |
| Rezept bearbeiten | ✅ | ✅ | – | `PUT /api/recipes/{id}` |
| Rezept loeschen | ✅ | ✅ | – | `DELETE /api/recipes/{id}` |
| Rezeptvorschlaege (selten gekocht) | – | – | ✅ | `GET /api/recipes/suggestions` |
| Kochhistorie anzeigen | – | ✅ | ✅ | `GET /api/recipes/{id}/history` |
| Bild-Anzeige (Cookidoo-Import) | ✅ | ✅ | – | `image_url` Feld |

---

## 8. Essensplanung (Wochenplan)

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Wochenplan anzeigen (Mo-So) | ✅ | ✅ | ✅ | `GET /api/meals/plan` |
| Slot belegen (Mittag/Abend) | ✅ | ✅ | ✅ | `PUT /api/meals/plan/{date}/{slot}` |
| Slot leeren | ✅ | ✅ | – | `DELETE /api/meals/plan/{date}/{slot}` |
| Als gekocht markieren (+ Bewertung) | ✅ | ✅ | ✅ | `PATCH /api/meals/plan/{date}/{slot}/done` |
| Schnellrezept erstellen beim Zuweisen | ✅ | – | – | – |
| Woche navigieren (vor/zurueck) | ✅ | ✅ | – | Query-Parameter `week` |
| "Schon lange nicht gekocht" Hinweis | ✅ | – | – | Frontend-Logik (>28 Tage) |

---

## 9. KI-Essensplanung (Claude API)

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Verfuegbare Rezepte + Slots laden | ✅ | – | – | `GET /api/ai/available-recipes` |
| Slot-Auswahl (welche Tage/Slots) | ✅ | – | – | Frontend-Dialog |
| Cookidoo-Rezeptpool einbeziehen | ✅ | – | – | `include_cookidoo` Parameter |
| KI-Vorschlag generieren (Preview) | ✅ | – | – | `POST /api/ai/generate-meal-plan` |
| KI-Begruendung anzeigen (Popup) | ✅ | – | – | Response-Feld `reasoning` |
| Vorschlag pruefen + Neu generieren | ✅ | – | – | Frontend-Dialog |
| Plan bestaetigen + speichern | ✅ | – | – | `POST /api/ai/confirm-meal-plan` |
| Auto-Einkaufsliste bei Bestaetigung | ✅ | – | – | Backend-Logik |
| Cookidoo-Rezepte auto-importieren | ✅ | – | – | Backend-Logik |
| Plan rueckgaengig machen (Undo) | ✅ | – | – | `POST /api/ai/undo-meal-plan` |
| Portionen + Wuensche konfigurieren | ✅ | – | – | Request-Parameter |

---

## 10. Einkaufsliste

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Aktive Einkaufsliste anzeigen | ✅ | ✅ | ✅ | `GET /api/shopping/list` |
| Aus Wochenplan generieren | ✅ | ✅ | ✅ | `POST /api/shopping/generate` |
| Artikel manuell hinzufuegen | ✅ | ✅ | ✅ | `POST /api/shopping/items` |
| Artikel abhaken / aufhaken | ✅ | ✅ | ✅ | `PATCH /api/shopping/items/{id}/check` |
| Artikel loeschen (nur manuelle) | ✅ | ✅ | – | `DELETE /api/shopping/items/{id}` |
| Gruppierung nach Kategorie | ✅ | ✅ | – | Frontend-Logik |
| Fortschrittsanzeige | ✅ | ✅ | – | Frontend-Logik |
| An Knuspr senden | ✅ | – | ✅ | `POST /api/knuspr/cart/send-list/{id}` |
| KI-Sortierung nach Supermarkt | ✅ | – | – | `POST /api/shopping/sort` |

### KI-Einkaufslisten-Sortierung

Sortiert die Einkaufsliste per Claude API nach dem typischen Gang-Layout eines deutschen Supermarkts (Eingang bis Kasse). Der User waehlt einen Supermarkt (Edeka, Lidl, Aldi, Penny, Netto), und die KI ordnet die Artikel in der Reihenfolge, in der man sie beim Gang durch den Laden antrifft. Jeder Artikel wird einer Supermarkt-Abteilung zugeordnet (z.B. "Obst & Gemuese", "Kuehlregal", "Tiefkuehl"). Die Sortierung wird in der DB persistiert.

---

## 11. Cookidoo-Integration (Thermomix)

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Verfuegbarkeit pruefen | ✅ | ✅ | – | `GET /api/cookidoo/status` |
| Collections durchblaettern | ✅ | ✅ | – | `GET /api/cookidoo/collections` |
| Cookidoo-Einkaufsliste anzeigen | ✅ | ✅ | – | `GET /api/cookidoo/shopping-list` |
| Rezeptdetails laden | ✅ | ✅ | ✅ | `GET /api/cookidoo/recipes/{id}` |
| Rezept importieren | ✅ | ✅ | ✅ | `POST /api/cookidoo/recipes/{id}/import` |
| Cookidoo-Wochenkalender | – | – | ✅ | `GET /api/cookidoo/calendar` |

---

## 12. Knuspr-Integration (Online-Supermarkt)

| Funktion | Web | Android | MCP | API-Endpunkt |
|----------|:---:|:-------:|:---:|-------------|
| Produkte suchen | – | – | ✅ | `GET /api/knuspr/products/search` |
| Produkt in Warenkorb | – | – | ✅ | `POST /api/knuspr/cart/add` |
| Einkaufsliste an Knuspr senden | ✅ | – | ✅ | `POST /api/knuspr/cart/send-list/{id}` |
| Lieferslots abrufen | – | – | ✅ | `GET /api/knuspr/delivery-slots` |
| Warenkorb leeren | – | – | ✅ | `DELETE /api/knuspr/cart` |

---

## 13. MCP-Server (Claude Desktop Integration)

28 Tools und 8 Resources fuer die Steuerung des Familienkalenders ueber Claude Desktop.

### Tools

| Tool | Funktion |
|------|----------|
| `get_events` | Events mit optionalem Datumsbereich und Kategorie-Filter |
| `create_event` | Event erstellen |
| `update_event` | Event aktualisieren |
| `delete_event` | Event loeschen |
| `get_todos` | Todos mit Filtern (Kategorie, Prioritaet, Status) |
| `create_todo` | Todo erstellen |
| `complete_todo` | Todo abschliessen/oeffnen |
| `delete_todo` | Todo loeschen |
| `get_agenda` | Agenda (Events + Todos) fuer Zeitraum |
| `get_open_todos_by_category` | Offene Todos nach Kategorie gruppiert |
| `link_todo_to_event` | Todo mit Event verknuepfen |
| `get_meal_plan` | Wochenplan abrufen |
| `set_meal_slot` | Slot mit Rezept belegen |
| `mark_as_cooked` | Als gekocht markieren + Kochhistorie |
| `get_cooking_history` | Kochhistorie eines Rezepts |
| `get_recipe_suggestions` | Rezeptvorschlaege (selten/nie gekocht) |
| `get_shopping_list` | Aktive Einkaufsliste |
| `generate_shopping_list` | Einkaufsliste aus Wochenplan generieren |
| `add_shopping_item` | Artikel manuell hinzufuegen |
| `check_shopping_item` | Artikel abhaken |
| `get_cookidoo_recipe` | Cookidoo-Rezeptdetails laden |
| `import_recipe_to_plan` | Cookidoo-Rezept importieren |
| `sync_cookidoo_week` | Cookidoo-Kalender abrufen |
| `search_knuspr_product` | Knuspr-Produktsuche |
| `add_to_knuspr_cart` | Produkt in Knuspr-Warenkorb |
| `send_shopping_list_to_knuspr` | Einkaufsliste an Knuspr senden |
| `get_knuspr_delivery_slots` | Knuspr-Lieferslots |
| `clear_knuspr_cart` | Knuspr-Warenkorb leeren |

### Resources

| URI | Inhalt |
|-----|--------|
| `calendar://today` | Tagesagenda (Events + Todos) |
| `calendar://week` | Wochenagenda (Mo-So) |
| `todos://open` | Alle offenen Todos |
| `todos://high-priority` | Offene Todos mit hoher Prioritaet |
| `shopping://current-list` | Aktive Einkaufsliste |
| `shopping://week-plan` | Wochenplan + Einkaufsliste kombiniert |
| `recipes://suggestions` | Top 5 Rezeptvorschlaege |
| `recipes://history` | Kochhistorie der letzten 90 Tage |

---

## 14. Android-exklusive Features

| Feature | Beschreibung |
|---------|-------------|
| **Offline-Modus** | Room-Cache + Pending-Change-Queue, Aenderungen werden bei Verbindung synchronisiert |
| **Hintergrund-Sync** | WorkManager, alle 15 Minuten automatisch |
| **Mehrere Kalenderansichten** | Monat, Woche, 3 Tage, Tag (Web nur Monat) |
| **Server-URL konfigurierbar** | In Login-Screen und Einstellungen |

---

## 15. KI-Sprachassistent (Voice Command)

Sprachgesteuerter Assistent, der auf jeder Seite per Floating-Button erreichbar ist. Spracheingabe wird per Browser Web Speech API transkribiert und an Claude gesendet, das die passenden Aktionen erkennt und ausfuehrt.

### Eingabe

| Funktion | Web | Android | MCP | Details |
|----------|:---:|:-------:|:---:|---------|
| Spracheingabe (Mikrofon) | ✅ | – | – | Web Speech API (`de-DE`), 5s Pause-Toleranz |
| Texteingabe-Fallback | ✅ | – | – | Fuer Browser ohne SpeechRecognition (z.B. Firefox) |
| Floating-Button auf allen Seiten | ✅ | – | – | FAB unten-rechts, Zustaende: idle / listening / processing |

### Unterstuetzte Aktionen per Sprache

| Aktion | Typ | Beispiel-Sprachbefehl |
|--------|-----|----------------------|
| Termin erstellen | `create_event` | "Am Montag um 14 Uhr Meeting mit Michi" |
| Serientermin erstellen | `create_recurring_event` | "Jeden Mittwoch um 18 Uhr Stammtisch bis Ende des Jahres" |
| Todo erstellen (+ Event-Link) | `create_todo` | "Ich muss noch Kaffee vorbereiten fuer das Meeting" |
| Rezept erstellen | `create_recipe` | "Neues Rezept Kartoffelsuppe, einfach, 30 Minuten" |
| Essensplan belegen | `set_meal_slot` | "Am Dienstag Abend gibt es Spaghetti Bolognese" |
| Einkaufsartikel hinzufuegen | `add_shopping_item` | "Fuege 500g Mehl zur Einkaufsliste hinzu" |
| Termin verschieben / bearbeiten | `update_event` | "Verschiebe das Meeting auf Mittwoch um 15 Uhr" |
| Todo bearbeiten | `update_todo` | "Aendere die Prioritaet von Dokument ausfuellen auf hoch" |
| Todo als erledigt markieren | `complete_todo` | "Kaffee vorbereiten ist erledigt" |
| Termin loeschen | `delete_event` | "Loesche den Termin Basketball Training" |
| Todo loeschen | `delete_todo` | "Loesche das Todo Dokument ausfuellen" |

### Intelligenz-Features

| Feature | Details |
|---------|---------|
| Kontexterkennung Familienmitglieder | "Meeting mit Michi" → ordnet Familienmitglied per Name zu |
| Wochentag-Aufloesung | "Am Montag" → berechnet korrektes Datum relativ zu heute |
| Referenz-System | Event + verknuepfte Todos in einem Sprachbefehl (automatische ID-Aufloesung) |
| Smart Context Loading | Bestehende Events/Todos werden nur bei Bearbeitungs-Befehlen geladen (Keyword-Erkennung), spart Tokens bei Create-Befehlen |
| Serientermine | Backend generiert bis zu 200 Einzeltermine aus einem Muster (taeglich/woechentlich/monatlich) |
| Ergebnis-Popup | Zeigt Zusammenfassung + Liste aller ausgefuehrten Aktionen mit Erfolgsstatus |
| Auto-Refresh | Aktive Ansicht wird nach Ausfuehrung automatisch aktualisiert |

### API

| Endpunkt | Zweck |
|----------|-------|
| `POST /api/ai/voice-command` | Sprachbefehl interpretieren und ausfuehren |

---

## 16. Multi-Tenancy (Familien-Isolation)

Alle Daten sind per `family_id` einer Familie zugeordnet. Jeder User gehoert zu genau einer Familie.

### Datenmodell

| Konzept | Details |
|---------|---------|
| **Family** | Kern-Entity mit `id`, `name`, `invite_code` (auto-generiert) |
| **User → Family** | `family_id` FK (nullable, bis User einer Familie beitritt) |
| **Scoped Models** | FamilyMember, Category, Event, Todo, Recipe, MealPlan, ShoppingList |
| **Indirekt scoped** | Ingredient (via Recipe), ShoppingItem (via ShoppingList), CookingHistory (via Recipe), TodoProposal (via Todo) |

### Flow

1. User registriert sich (`POST /api/auth/register`)
2. User erstellt Familie (`POST /api/auth/family`) oder tritt bei (`POST /api/auth/family/join`)
3. Alle weiteren Endpunkte erfordern `family_id` — ohne Familie gibt es HTTP 403
4. Default-Kategorien werden automatisch beim Erstellen einer Familie geseedet

### Sicherheit

- `require_family_id` Dependency prueft bei jedem Request
- Alle Queries filtern nach `family_id`
- Get/Update/Delete pruefen, dass der Datensatz zur Familie gehoert
- MCP-Server nutzt konfigurierbare `MCP_FAMILY_ID` Umgebungsvariable

---

## API-Endpunkt-Statistik

| Router | Prefix | Endpunkte |
|--------|--------|-----------|
| auth | `/api/auth` | 7 |
| events | `/api/events` | 5 |
| todos | `/api/todos` | 7 |
| proposals | `/api/proposals` + `/api/todos` | 4 |
| recipes | `/api/recipes` | 7 |
| meals | `/api/meals` | 4 |
| shopping | `/api/shopping` | 6 |
| cookidoo | `/api/cookidoo` | 6 |
| knuspr | `/api/knuspr` | 5 |
| ai | `/api/ai` | 5 |
| categories | `/api/categories` | 4 |
| family_members | `/api/family-members` | 4 |
| **Gesamt** | | **64 Endpunkte** |
