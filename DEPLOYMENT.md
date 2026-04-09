# Deployment auf Synology NAS mit DDNS

## Uebersicht

```
Internet → Router (Port 443) → Synology Reverse Proxy (HTTPS/SSL)
    → Docker-Container: nginx (:8443) → flutter (:80) + api (:8000) + db (:5432)
```

**Ergebnis:** Die App ist unter `https://DEIN-NAME.synology.me` erreichbar — vom Handy, ohne VPN.

---

## Voraussetzungen

- Synology NAS mit DSM 7.x
- Docker-Paket installiert (Container Manager)
- Zugang zum Router (fuer Port-Forwarding)
- SSH-Zugang zum NAS aktiviert

---

## Schritt 1: Synology DDNS einrichten

1. **DSM oeffnen** → Systemsteuerung → Externer Zugriff → DDNS
2. **Hinzufuegen** klicken:
  - Dienstanbieter: **Synology**
  - Hostname: Waehle einen Namen, z.B. `familienkalender` → ergibt `familienkalender.synology.me`
  - Heartbeat aktivieren: **Ja**
3. **Verbindungsstatus testen** → muss "Normal" anzeigen

## Schritt 2: Let's Encrypt Zertifikat

1. DSM → Systemsteuerung → Sicherheit → Zertifikat
2. **Hinzufuegen** → Neues Zertifikat hinzufuegen → **Von Let's Encrypt beziehen**
3. Eingaben:
  - Domainname: `familienkalender.synology.me` (dein DDNS-Name)
  - E-Mail: Deine E-Mail-Adresse
4. **Uebernehmen** — DSM holt automatisch das Zertifikat
5. **Wichtig:** Dieses Zertifikat als Standard-Zertifikat setzen

> DSM erneuert das Zertifikat automatisch alle 90 Tage.

## Schritt 3: Port-Forwarding am Router

In deiner Router-Konfiguration (z.B. Fritz!Box, Speedport):


| Externer Port | Interner Port | Protokoll | Ziel-IP                            |
| ------------- | ------------- | --------- | ---------------------------------- |
| 443           | 443           | TCP       | IP deines NAS (z.B. 192.168.1.100) |


**Nur Port 443!** Keine weiteren Ports oeffnen.

### Fritz!Box Beispiel

1. Internet → Freigaben → Portfreigaben
2. Geraet: Dein NAS auswaehlen
3. Neue Freigabe: Port 443 extern → Port 443 intern, TCP

## Schritt 4: Synology Reverse Proxy einrichten

1. DSM → Systemsteuerung → Anmeldeportal → Erweitert → Reverse Proxy
2. **Erstellen** klicken:


| Feld              | Wert                           |
| ----------------- | ------------------------------ |
| Beschreibung      | Familienkalender               |
| Quelle: Protokoll | HTTPS                          |
| Quelle: Hostname  | `familienkalender.synology.me` |
| Quelle: Port      | 443                            |
| Ziel: Protokoll   | HTTP                           |
| Ziel: Hostname    | localhost                      |
| Ziel: Port        | 8080                           |


1. Unter **Benutzerdefinierter Header** folgende Header hinzufuegen:
  - `X-Real-IP` → `$remote_addr`
  - `X-Forwarded-For` → `$proxy_add_x_forwarded_for`
  - `X-Forwarded-Proto` → `$scheme`
  - `Upgrade` → `$http_upgrade`
  - `Connection` → `$connection_upgrade`
2. **Uebernehmen**
3. Unter Systemsteuerung → Sicherheit → Zertifikat → **Konfigurieren**:
  - Dem Reverse-Proxy-Eintrag "Familienkalender" das Let's Encrypt Zertifikat zuweisen

> **Ergebnis:** Synology terminiert SSL auf Port 443 und leitet an Docker-Container auf Port 8080 weiter.

## Schritt 5: Projekt aufs NAS bringen

### Option A: Git (empfohlen)

```bash
# Auf dem NAS per SSH:
cd /volume1/docker
git clone <dein-repo-url> familienkalender
cd familienkalender
```

### Option B: Dateien kopieren

Per SMB/CIFS (Windows-Freigabe) oder SCP das Projektverzeichnis nach `/volume1/docker/familienkalender/` kopieren.

## Schritt 6: Umgebungsvariablen einrichten

```bash
# Auf dem NAS per SSH:
cd /volume1/docker/familienkalender

# Template kopieren
cp .env.production.template .env.production

# Bearbeiten
vi .env.production
```

**Wichtig — diese Werte MUESSEN geaendert werden:**

```bash
# Sicheres DB-Passwort generieren:
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Sicheren SECRET_KEY generieren:
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

Die generierten Werte in `.env.production` eintragen:

```
POSTGRES_PASSWORD=<generiertes-passwort>
SECRET_KEY=<generierter-key>
CORS_ORIGINS=https://familienkalender.synology.me
```

Plus deine Cookidoo/Knuspr/Anthropic-Credentials.

## Schritt 7: SSL-Zertifikate fuer Nginx verlinken

Der Nginx-Container in Docker braucht Zugriff auf die Let's Encrypt Zertifikate von DSM:

```bash
# Auf dem NAS per SSH:
cd /volume1/docker/familienkalender

# SSL-Verzeichnis erstellen
mkdir -p ssl

# Finde das richtige Zertifikat-Verzeichnis:
ls /usr/syno/etc/certificate/_archive/

# Es gibt Ordner mit zufaelligen Namen. Finde den richtigen:
# (Der DEFAULT-Eintrag zeigt auf den richtigen Ordner)
cat /usr/syno/etc/certificate/_archive/DEFAULT

# Dann verlinke die Zertifikate (XXXXXX durch den Ordnernamen ersetzen):
ln -sf /usr/syno/etc/certificate/_archive/XXXXXX/fullchain.pem ssl/fullchain.pem
ln -sf /usr/syno/etc/certificate/_archive/XXXXXX/privkey.pem ssl/privkey.pem
```

### Alternative: Ohne eigenen SSL-Container (einfacher)

Da der Synology Reverse Proxy bereits SSL terminiert, kannst du den SSL-Teil auch weglassen und direkt HTTP auf Port 8080 durchreichen. In diesem Fall nutze diese **vereinfachte Architektur**:

```
Internet → Router (:443) → Synology Reverse Proxy (SSL) → Docker flutter (:8080)
    flutter-nginx → /api/ proxy_pass → api (:8000)
```

Dafuer die `docker-compose.prod.yml` aendern: den `nginx`-Service entfernen und stattdessen dem `flutter`-Service Port 8080 geben:

```yaml
  flutter:
    build: ./flutter
    container_name: familienkalender-flutter
    ports:
      - "8080:80"
    depends_on:
      - api
    restart: unless-stopped
```

Den Synology Reverse Proxy dann auf `localhost:8080` zeigen lassen.

> **Empfehlung:** Die vereinfachte Variante ist fuer den Start einfacher. Der separate Nginx-Container mit SSL lohnt sich nur, wenn du spaeter weitere Services auf dem NAS betreiben willst.

## Schritt 8: Container bauen und starten

```bash
# Auf dem NAS per SSH:
cd /volume1/docker/familienkalender

# Bauen und starten
docker-compose -f docker-compose.prod.yml up -d --build

# Logs pruefen
docker-compose -f docker-compose.prod.yml logs -f

# Status pruefen
docker-compose -f docker-compose.prod.yml ps
```

## Schritt 9: Testen

1. **Lokal auf dem NAS:** `curl http://localhost:8080` → sollte HTML zurueckgeben
2. **Im Heimnetz:** `https://familienkalender.synology.me` im Browser oeffnen
3. **Vom Handy (ueber Mobilfunk):** WLAN deaktivieren, `https://familienkalender.synology.me` oeffnen
4. **Flutter-App:** Server-URL auf `https://familienkalender.synology.me` setzen

---

## Wartung

### Logs anschauen

```bash
docker-compose -f docker-compose.prod.yml logs -f api
docker-compose -f docker-compose.prod.yml logs -f flutter
```

### Update deployen

```bash
cd /volume1/docker/familienkalender
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

### Datenbank-Backup

```bash
docker exec familienkalender-db pg_dump -U kalender kalender > backup_$(date +%Y%m%d).sql
```

### Datenbank wiederherstellen

```bash
cat backup_YYYYMMDD.sql | docker exec -i familienkalender-db psql -U kalender kalender
```

---

## Fehlerbehebung


| Problem                    | Loesung                                                                   |
| -------------------------- | ------------------------------------------------------------------------- |
| "Bad Gateway" im Browser   | `docker-compose ps` — laufen alle Container?                              |
| Zertifikat-Warnung         | Let's Encrypt Zertifikat erneuern (DSM → Sicherheit → Zertifikat)         |
| API nicht erreichbar       | `docker-compose logs api` pruefen                                         |
| Vom Handy nicht erreichbar | Port-Forwarding am Router pruefen, DDNS-Status in DSM checken             |
| CORS-Fehler                | `CORS_ORIGINS` in `.env.production` pruefen                               |
| Login geht nicht           | `SECRET_KEY` darf sich nicht aendern (sonst werden alle Tokens ungueltig) |
| Container starten nicht    | `docker-compose -f docker-compose.prod.yml logs` fuer Details             |


---

## Sicherheits-Checkliste

- `POSTGRES_PASSWORD` ist ein zufaelliger String (nicht "kalender")
- `SECRET_KEY` ist ein zufaelliger String (nicht der Default)
- `CORS_ORIGINS` enthaelt nur deine Domain
- Nur Port 443 am Router offen
- DSM-Admin-Account hat 2FA aktiviert
- SSH auf dem NAS hat ein starkes Passwort oder Key-Auth
- `.env.production` ist NICHT in Git committed

