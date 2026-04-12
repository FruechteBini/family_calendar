# Frontend Design Plan: "Familienherd" — Dark Mode

> **Zielgruppe:** KI-Agenten, die das Flutter-Frontend implementieren
> **Design-System:** "Kindred Hearth" (Dark Mode / Midnight Sanctuary)
> **Letzte Aktualisierung:** 2026-04-08

---

## 1. Design-Philosophie

Das Design folgt dem Konzept **"Bioluminescent Hearth"** — ein warmes, atmosphaerisches Dark-Theme, das sich von klinischen Dark Modes abhebt. Die App soll sich anfuehlen wie ein digitales Zuhause: gemuetlich, modern und hochwertig.

### Kernprinzipien

1. **No-Line Rule:** Keine 1px-Borders zur Trennung. Grenzen werden ausschliesslich durch Hintergrundfarb-Wechsel definiert
2. **Tonal Layering:** Tiefe entsteht durch Farbschichten, nicht durch Schatten
3. **Editorial Typography:** Uebergrosse Headlines, asymmetrische Layouts, Magazin-Feeling
4. **Glassmorphism:** Schwebende Elemente nutzen Blur + Transparenz
5. **Soft Corners:** Mindestens 16px Border-Radius ueberall

---

## 2. Farbsystem (Dark Mode)

### Primaere Oberflaechen

| Token | Hex | Verwendung |
|-------|-----|------------|
| `surface` / `background` | `#131312` | App-Hintergrund, Basis-Layer |
| `surfaceDim` | `#131312` | Identisch mit surface |
| `surfaceContainerLowest` | `#0E0E0C` | Tiefste Ebene, Inset-Bereiche (Suchfelder, inaktive Zonen) |
| `surfaceContainerLow` | `#1C1C1A` | Sektions-Hintergruende, Gruppen |
| `surfaceContainer` | `#20201E` | Standard-Container |
| `surfaceContainerHigh` | `#2A2A28` | Karten, interaktive Container |
| `surfaceContainerHighest` | `#353532` | Popovers, erhoehte Elemente |
| `surfaceVariant` | `#353532` | Alternative Oberflaechen |

### Akzentfarben

| Token | Hex | Verwendung |
|-------|-----|------------|
| `primary` | `#66D9CC` | Neon-Teal, Haupt-Aktionsfarbe, aktive Nav-Items |
| `primaryContainer` | `#26A69A` | Teal dunkel, Gradient-Start, Buttons |
| `primaryFixed` | `#84F5E8` | Leucht-Details (Notification-Dots, kleine Akzente) |
| `onPrimary` | `#003732` | Text auf Primary |
| `onPrimaryContainer` | `#003430` | Text auf PrimaryContainer |
| `secondary` | `#FFD799` | Warmes Amber, emotionale Highlights |
| `secondaryContainer` | `#FEB300` | Starkes Amber, Warnungen, "Hearth Glow" |
| `onSecondary` | `#432C00` | Text auf Secondary |
| `tertiary` | `#FFB59B` | Orange-Akzent |
| `tertiaryContainer` | `#DA7C5A` | Sonntage, Kategorien |
| `error` | `#FFB4AB` | Fehler, dringende Termine |
| `errorContainer` | `#93000A` | Fehler-Container |

### Text- und Rahmenfarben

| Token | Hex | Verwendung |
|-------|-----|------------|
| `onSurface` | `#E5E2DE` | Primaerer Text (NIEMALS reines Weiss #FFF verwenden!) |
| `onSurfaceVariant` | `#BCC9C6` | Sekundaerer Text, Labels, Metadata |
| `outline` | `#869391` | Sichtbare Rahmen (sparsam) |
| `outlineVariant` | `#3D4947` | Ghost-Borders bei 15% Opacity |
| `inverseSurface` | `#E5E2DE` | Inverse Badges |
| `inverseOnSurface` | `#31302E` | Text auf inversem Hintergrund |
| `inversePrimary` | `#006A62` | Primary auf inversem Hintergrund |
| `surfaceTint` | `#66D9CC` | Tint fuer Elevation |

### Gradient-Definitionen

```dart
// Teal-Gradient fuer Primary Buttons und Hero-CTAs
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight, // 135 Grad
  colors: [Color(0xFF26A69A), Color(0xFF66D9CC)],
)

// Amber-Gradient fuer Secondary/Highlight
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFEB300), Color(0xFFFFD799)],
)
```

---

## 3. Typografie

### Schriftarten

| Rolle | Font | Verwendung |
|-------|------|------------|
| **Display & Headlines** | Plus Jakarta Sans | Alle grossen Ueberschriften, Sektions-Titel, Hero-Texte |
| **Body & Labels** | Inter | Fliesstext, Metadaten, kleine Labels |

### Typ-Skala

| Style | Font | Groesse | Gewicht | Letter-Spacing | Verwendung |
|-------|------|---------|---------|-----------------|------------|
| `displayLarge` | Plus Jakarta Sans | 57px | 800 | -0.02em | Hero-Momente (selten) |
| `displayMedium` | Plus Jakarta Sans | 45px | 800 | -0.02em | Feature-Headlines |
| `displaySmall` | Plus Jakarta Sans | 36px | 800 | -0.02em | Seiten-Titel |
| `headlineLarge` | Plus Jakarta Sans | 32px | 700 | -0.01em | Sektions-Ueberschriften |
| `headlineMedium` | Plus Jakarta Sans | 28px | 700 | -0.01em | Sub-Sektionen |
| `headlineSmall` | Plus Jakarta Sans | 24px | 700 | normal | Karten-Titel |
| `titleLarge` | Plus Jakarta Sans | 22px | 700 | normal | Navigation, Karten-Header |
| `titleMedium` | Plus Jakarta Sans | 16px | 600 | normal | Listen-Titel |
| `titleSmall` | Plus Jakarta Sans | 14px | 600 | normal | Kleine Titel |
| `bodyLarge` | Inter | 16px | 400 | normal | Primaerer Fliesstext |
| `bodyMedium` | Inter | 14px | 400 | normal | Standard-Text |
| `bodySmall` | Inter | 12px | 400 | normal | Hilfstexte |
| `labelLarge` | Inter | 14px | 600 | +0.01em | Button-Labels |
| `labelMedium` | Inter | 12px | 500 | +0.05em | Kategorie-Tags, Badges (UPPERCASE) |
| `labelSmall` | Inter | 11px | 500 | +0.05em | Kleinste Labels |

### Typografie-Regeln

- **Maximal 3 Typ-Ebenen pro Karte** — z.B. `titleMedium` + `bodyMedium` + `labelSmall`
- Headlines tight setzen (`letterSpacing: -0.02em`) fuer Editorial-Feel
- `onSurfaceVariant` fuer sekundaere Infos → reduziert Augenbelastung
- `labelMedium` in UPPERCASE mit erhoehtem Letter-Spacing fuer Tags

---

## 4. Elevation & Tiefe

### Tonal Layering (statt Schatten)

Tiefe wird durch Farbwechsel erzeugt. Die Hierarchie:

```
Level 0 (Basis):     surface         #131312
Level 1 (Sektionen): surfaceContainerLow   #1C1C1A
Level 2 (Karten):    surfaceContainerHigh  #2A2A28
Level 3 (Popovers):  surfaceContainerHighest #353532
```

**Beispiel:** Eine Event-Karte (`surfaceContainerHigh`) auf einem Tages-Abschnitt (`surfaceContainerLow`) erzeugt natuerlichen "Lift".

### Ambient Glow (statt Drop-Shadow)

Wenn ein Element schweben muss (FAB, Modale):

```dart
BoxShadow(
  color: Color(0xFF66D9CC).withOpacity(0.08), // Primary bei 8%
  blurRadius: 40,
  spreadRadius: -5,
  offset: Offset.zero,
)
```

### Ghost-Border (Accessibility-Fallback)

Falls eine Container-Grenze benoetigt wird:

```dart
Border.all(
  color: Color(0xFF3D4947).withOpacity(0.15), // outlineVariant bei 15%
  width: 1,
)
```

### Glassmorphism fuer schwebende Elemente

```dart
// Fuer Navigation-Bar, Modale, Overlays
Container(
  decoration: BoxDecoration(
    color: Color(0xFF131312).withOpacity(0.80),
    borderRadius: BorderRadius.circular(48), // rounded-t-[3rem]
  ),
  child: ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: content,
    ),
  ),
)
```

---

## 5. Border-Radius Tokens

| Token | Wert | Verwendung |
|-------|------|------------|
| `radiusDefault` | 16px | Karten, Buttons, Input-Felder |
| `radiusMedium` | 24px | Dialoge, Bottom-Sheets |
| `radiusLarge` | 32px | Grosse Container, Top-Level-Screens |
| `radiusXL` | 48px | Navigation-Bar (rounded-t-[3rem]) |
| `radiusFull` | 9999px | Pillen-Buttons, Chips, Avatare |

**Regel:** Niemals scharfe Ecken. Jedes Element mindestens `radiusDefault` (16px).

---

## 6. Spacing-System

| Token | Wert | Verwendung |
|-------|------|------------|
| `spacing2` | 8px | Minimaler Abstand, Icon-Gaps |
| `spacing3` | 12px | Listen-Items untereinander |
| `spacing4` | 16px | Karten-Padding, Standard-Gap |
| `spacing6` | 24px | Screen-Padding horizontal |
| `spacing8` | 32px | Sektions-Abstand |
| `spacing12` | 48px | Grosse Sektions-Trennung |

**Keine Divider-Lines!** Trennung zwischen Listen-Items durch `spacing3` (12px) Abstand ODER Wechsel der Hintergrundfarbe.

---

## 7. Komponenten-Bibliothek

### 7.1 Buttons

#### Primary Button (Gradient)
```
- Form: rounded-full (Pille)
- Hintergrund: Teal-Gradient (primaryContainer → primary)
- Text: onPrimaryContainer, labelLarge, bold
- Padding: 32px horizontal, 16px vertikal
- Kein Shadow, stattdessen: subtiles inner-Glow
- Hover/Press: scale(1.05) → scale(0.95) Transition
- Icon links moeglich (Material Symbols Outlined)
```

#### Secondary Button (Ghost)
```
- Form: rounded-full
- Hintergrund: surfaceContainerHighest
- Text: primary (Teal)
- Kein Border
- Hover: Hintergrund wechselt zu surfaceContainerHigh
```

#### Tertiary Button (Text-only)
```
- Kein Hintergrund
- Text: primary, bold
- Unterstrichen mit 2px secondary Stroke (optional)
```

### 7.2 Karten

#### Standard-Karte
```
- Hintergrund: surfaceContainerHigh (#2A2A28)
- Border-Radius: 16px (radiusDefault)
- Padding: 16-20px
- Kein Border, kein Shadow
- Hover: Transition zu surfaceContainerHighest (200ms ease)
```

#### Event-Karte (mit Farbbalken)
```
- Standard-Karte + 4px linker Farbbalken (border-left)
- Farbbalken-Farbe = Kategorie/Mitglied-Farbe
- Layout: [Zeit-Spalte (50px) | Inhalt | Optional: Avatar]
- Zeit: labelSmall, bold, Farbe = Balken-Farbe
- Titel: titleMedium, bold, onSurface
- Details: bodySmall, onSurfaceVariant + Icon
```

#### Hero-Karte (Dinner/Rezept)
```
- Volle Breite, surfaceContainerLow Hintergrund
- Bild oben: Cover-Bild mit Gradient-Overlay (transparent → background)
- Content ueberlappt Bild um -80px (negative margin)
- Tag-Chip: secondary Hintergrund, labelSmall, UPPERCASE, bold, tracking-widest
- Titel: displaySmall oder headlineLarge, extrabold
- Beschreibung: bodyMedium, onSurfaceVariant
- CTA-Button: Primary Gradient, rounded-full
```

### 7.3 Input-Felder

```
- Form: Pill-foermig (rounded-full) ODER radiusDefault (16px)
- Hintergrund: surfaceContainerLowest (#0E0E0C)
- Kein Border im Normalzustand
- Focus: 2px Ghost-Border in primary bei 40% Opacity
- Text: bodyLarge, onSurface
- Placeholder: bodyMedium, onSurfaceVariant
- Padding: 16px horizontal, 12px vertikal
```

### 7.4 Chips / Filter

```
- Form: rounded-full
- Inaktiv: surfaceVariant Hintergrund, onSurfaceVariant Text
- Aktiv: secondaryContainer Hintergrund, onSecondaryContainer Text
- Padding: 12px horizontal, 6px vertikal
- Text: labelMedium
```

### 7.5 Checkboxen / Todo-Items

```
- Runder Checkbox-Kreis: 24x24, 2px Border
- Unchecked: outlineVariant Border, kein Fill
- Checked: primary Border + primary Check-Icon (18px)
- Priority: secondary Border + priority_high Icon
- Item-Zeile: rounded-full, surfaceContainerLowest Hintergrund
- Hover: surfaceContainerHigh
- Text: bodyMedium, onSurface, font-medium
```

### 7.6 Badges / Tags

```
- Pill-Form: rounded-full
- Hintergrund: surfaceContainerHigh
- Text: labelMedium, bold, onSurfaceVariant
- Padding: 16px horizontal, 4px vertikal
- Variante "Warning": secondaryContainer bg, onSecondaryContainer text
```

### 7.7 Notification Dots

```
- Groesse: 8x8 bis 16x16
- Farbe: primaryFixed (#84F5E8) — "Gluehbirne im Dunkeln"
- Position: top-right des Parent-Elements
- Border: 2px background-farbener Rand
```

---

## 8. Navigation

### 8.1 Bottom Navigation Bar

Die Navigation ist ein zentrales Design-Element mit Glassmorphism-Effekt.

```
Struktur:
- Position: fixed bottom
- Hintergrund: surface (#131312) bei 80% Opacity + backdrop-blur 20px
- Border-Radius oben: 48px (radiusXL / rounded-t-[3rem])
- Shadow: 0 -4px 40px rgba(0,0,0,0.06)
- Padding: 12px oben, 24px unten (Safe Area), 16px horizontal

Items (5 Stueck):
- Icons: Material Symbols Outlined
- Labels: Plus Jakarta Sans, 11px, medium, UPPERCASE, tracking-wide
- Layout: Vertikal (Icon + Label)

Zustaende:
- INAKTIV: Farbe surfaceContainerHighest (#353532)
- HOVER: Farbe primary (#66D9CC)
- AKTIV: primaryContainer (#26A69A) Hintergrund-Pille,
         Text/Icon: surface (#131312)
         Form: rounded-full
         Padding: 20px horizontal, 8px vertikal
         Transition: scale(0.9) bei Press, 200ms

Tab-Items:
1. "Heute"    → Icon: today           → Route: /today
2. "Kalender" → Icon: calendar_month  → Route: /calendar
3. "Aufgaben" → Icon: assignment      → Route: /todos
4. "Essen"    → Icon: restaurant      → Route: /meals
5. "Einkauf"  → Icon: shopping_cart   → Route: /shopping
```

### 8.2 Top App Bar

```
- Position: fixed top, volle Breite
- Hintergrund: surface (#131312), KEIN Blur (solide)
- Padding: 24px horizontal, 16px vertikal
- Hoehe: ~64px

Links:
- User-Avatar: 40x40, rounded-full, 2px Border primaryContainer
- App-Titel: "Familienherd", Plus Jakarta Sans, 20px, w700, primary (#66D9CC)

Rechts:
- Action-Button: 40x40, rounded-full
- Icon: "search" (Material Symbols), primary-Farbe
- Hover: surfaceContainerHighest Hintergrund
```

### 8.3 Voice FAB (Floating Action Button)

```
Position: fixed, bottom-right, ueber der Navigation (bottom: 112px, right: 32px)

Form: 64x64 rounded-full
Hintergrund: Amber-Gradient (secondaryContainer → secondary)
Icon: "mic" (Material Symbols, FILL 1), 30px
Text/Icon-Farbe: onSecondaryContainer
Shadow: standard elevation shadow (xl)
Interaktion: hover scale(1.1), press scale(0.95)

Zustaende:
- IDLE: Amber-Gradient, mic Icon
- LISTENING: error (#FFB4AB) Hintergrund, mic Icon, pulsierender Ring
- PROCESSING: tertiary Hintergrund, hourglass_top Icon
```

---

## 9. Screen-Layouts

### 9.1 Dashboard / Heute-Screen

**Referenz-Mockup:** `dashboard_dark_kindred/screen.png`

```
ScrollView (vertikal):

1. TOP APP BAR (fixed)
   → Avatar + "Familienherd" + Search-Icon

2. FAMILY STATUS BUBBLES (horizontal scrollbar)
   ├── Pro Mitglied:
   │   ├── Aeusserer Ring: 64x64, rounded-full, 2px Border
   │   │   (Farbe = Status: primary=online, secondary=beschaeftigt, outline=offline)
   │   ├── Avatar-Bild: 56x56, rounded-full, object-cover
   │   ├── Status-Dot: 16x16, unten-rechts
   │   │   (primary=online, outline=offline)
   │   └── Name: labelMedium, UPPERCASE, tracking-wide, 11px
   └── Abstand zwischen Bubbles: 16px
   Sektion-Margin-Bottom: 48px

3. HEARTH HERO CARD (Heutiges Abendessen)
   ├── Container: surfaceContainerLow, radiusLarge (32px), overflow hidden
   ├── Bild: volle Breite, Hoehe 256px, object-cover
   ├── Gradient-Overlay: transparent → background (von oben nach unten)
   ├── Content (ueberlappt Bild, -80px margin-top, z-index 10):
   │   ├── Tag: secondary bg, onSecondary text, rounded-full
   │   │   labelSmall, bold, UPPERCASE, tracking-widest
   │   │   Text: "Heutiges Abendessen"
   │   ├── Titel: headlineLarge (32-40px), extrabold, onSurface
   │   ├── Beschreibung: bodyMedium, onSurfaceVariant, max-width 320px
   │   └── CTA: Primary Gradient Button, rounded-full
   │       Icon: restaurant_menu + "Rezept ansehen"
   └── Padding: 32px
   Sektion-Margin-Bottom: 48px

4. KALENDER-SEKTION
   ├── Header-Zeile:
   │   ├── Titel: headlineMedium (24px), bold
   │   └── Rechts: "Alle sehen", labelMedium, primary
   ├── Event-Liste (vertikal, spacing 16px):
   │   └── Event-Karte (je):
   │       ├── surfaceContainerHigh, radiusDefault (16px)
   │       ├── 4px linker Farbbalken (Kategorie-Farbe)
   │       ├── Zeit-Spalte: 50px, labelSmall, bold, Balken-Farbe
   │       ├── Titel: titleMedium, bold, onSurface
   │       └── Ort: bodySmall, onSurfaceVariant, location_on Icon
   └── Sektion-Margin-Bottom: 32px

5. AUFGABEN-SEKTION
   ├── Header-Zeile:
   │   ├── Titel: headlineMedium, bold
   │   └── Rechts: more_horiz Icon
   └── Todo-Liste (vertikal, spacing 8px):
       └── Todo-Item (je):
           ├── rounded-full, surfaceContainerLowest
           ├── Padding: 16px
           ├── Checkbox-Kreis: 24x24 (siehe Komponente 7.5)
           └── Text: bodyMedium, onSurface, font-medium
```

### 9.2 Kalender-Screen

**Referenz-Mockup:** `kalender_dark_kindred/screen.png`

```
ScrollView (vertikal):

1. TOP APP BAR (identisch)

2. KALENDER-HEADER
   ├── Ueberzeile: labelMedium, UPPERCASE, tracking +0.05em, secondary, "KALENDERANSICHT"
   ├── Monats-Titel: displaySmall (36px) oder headlineLarge (32px)
   │   extrabold, tracking-tight, onSurface
   │   Text: "Juli 2024"
   ├── Untertitel: bodySmall, onSurfaceVariant
   │   Text: "{n} Termine heute"
   └── Navigation-Pfeile (rechts, vertikal zentriert):
       2x Buttons: 40x40, rounded-full, surfaceContainerLow
       Icons: chevron_left / chevron_right, primary
       Hover: surfaceContainerHigh

3. KALENDER-GRID
   ├── Container: surfaceContainerLow, radiusLarge (32px)
   │   Shadow: 0 4px 40px rgba(0,0,0,0.15)
   │   Padding: 24px
   ├── Wochentag-Header (7 Spalten):
   │   Text: labelMedium, bold, onSurfaceVariant bei 50% opacity
   │   Sonntag (SO): secondary Farbe, volle Opacity
   ├── Tages-Grid (7x6):
   │   ├── Normal: bodySmall, font-medium, onSurface
   │   ├── Anderer Monat: 20% Opacity
   │   ├── Sonntag: secondary Farbe
   │   ├── Heute/Ausgewaehlt:
   │   │   Kreis: 32x32, primary Hintergrund
   │   │   Text: bold, onPrimaryContainer
   │   └── Event-Dots (unter der Zahl):
   │       Max 3 Dots, 4x4 rounded-full
   │       Farbe = Kategorie (primary, secondary, error, etc.)
   │       Gap: 2px
   └── Margin-Bottom: 40px

4. TAGES-HEADER
   ├── Titel: headlineMedium (24px), bold
   │   Text: "Heute, 12. Juli"
   └── Badge (rechts): surfaceContainerHigh, rounded-full
       Text: "{n} Termine", labelMedium, bold, onSurfaceVariant

5. EVENTS-LISTE (spacing 16px)
   └── Event-Karte (je):
       ├── surfaceContainerHigh, radiusDefault (16px)
       ├── Hover: surfaceContainerHighest, 200ms transition
       ├── Padding: 20px
       ├── Layout: [Zeit-Spalte | Inhalt | More-Button]
       ├── Zeit-Spalte (48px breit):
       │   ├── Zeit: labelSmall, bold, Kategorie-Farbe
       │   └── Vertikale Linie: 0.5px, outlineVariant bei 30%, 48px lang
       ├── Inhalt:
       │   ├── Dot (8x8, Kategorie-Farbe) + Titel (titleMedium, bold)
       │   └── Detail-Zeile: bodySmall, onSurfaceVariant
       │       Icon (16px) + Ort/Person
       └── More-Button: opacity 0, bei Hover opacity 1
           Icon: more_vert, onSurfaceVariant

6. FAB (Event hinzufuegen)
   Position: bottom-right (bottom: 128px, right: 24px)
   Groesse: 64x64, rounded-full
   Hintergrund: Teal-Gradient
   Icon: "add", 30px, onPrimaryContainer
   Shadow: elevation xl
```

### 9.3 Essensplanung / Wochenplan

**Referenz-Mockup:** `essen_dark_kindred/screen.png`

```
ScrollView (vertikal):

1. HEADER
   ├── Titel: "Wochenplan Essen", displaySmall (36px), extrabold
   ├── Untertitel: bodySmall, onSurfaceVariant
   │   Text: "KW {n} · {Datum} – {Datum}"
   └── Action-Chip: primaryContainer, rounded-full
       Icon: auto_awesome + "KI Vorschlag"

2. TAGES-SEKTIONEN (pro Tag, spacing 32px)
   └── Tages-Block:
       ├── Tag-Label: titleLarge (22px), bold, onSurface
       │   Text: "Montag", "Dienstag", etc.
       └── Mahlzeit-Karten (horizontal oder vertikal):
           └── Mahlzeit-Karte:
               ├── surfaceContainerHigh, radiusDefault (16px)
               ├── Bild: Breite variabel, Hoehe 80-120px
               │   rounded-top oder rounded-left
               │   Gradient-Overlay falls noetig
               ├── Inhalt:
               │   ├── Mahlzeit-Typ: labelSmall, primary, UPPERCASE
               │   │   ("MITTAGESSEN" / "ABENDESSEN")
               │   ├── Rezept-Name: titleMedium, bold
               │   └── Meta: bodySmall, onSurfaceVariant
               └── Leerer Slot:
                   Gestrichelte Umrandung (outlineVariant, 15%)
                   Text: "Gericht hinzufuegen", onSurfaceVariant
                   Icon: add_circle_outline

3. AI-VORSCHLAEGE SEKTION
   ├── Titel: headlineMedium, bold
   │   Icon: auto_awesome + "Vorschlaege fuer dich"
   └── Horizontaler Scroll (Karten):
       └── Vorschlags-Karte:
           ├── Breite: 200px, Hoehe: 240px
           ├── Bild oben: 140px, object-cover
           ├── Gradient-Overlay
           ├── Titel: titleSmall, bold, onSurface
           └── Tags: labelSmall, onSurfaceVariant
```

### 9.4 Einkaufsliste

**Referenz-Mockup:** `einkauf_dark_kindred/screen.png`

```
ScrollView (vertikal):

1. HEADER
   ├── Titel: "Einkauf", displaySmall (36px), extrabold
   └── Fortschritt: bodySmall, onSurfaceVariant
       Text: "{erledigt} von {gesamt} erledigt"

2. ACTION-BUTTONS (horizontal, spacing 12px)
   ├── Button: primaryContainer, rounded-full, Icon + Text
   │   "Sync with Meal Plan" (oder "KI Sortierung")
   └── Button: surfaceContainerHigh, rounded-full
       "Send to Knuspr"

3. PANTRY ALERTS (konditionell)
   ├── Container: secondaryContainer bei 30% Opacity, radiusDefault
   ├── Icon: warning, secondary
   ├── Titel: "PANTRY ALERTS", labelMedium, bold, UPPERCASE
   └── Items: bodySmall, onSurface
       Pro Alert: Item-Name + Grund + "Hinzufuegen" Button (secondary)

4. INPUT-FELD
   ├── Pill-Form, surfaceContainerLowest
   ├── Placeholder: "Neuen Artikel hinzufuegen..."
   ├── Links: Icon (z.B. add_shopping_cart)
   └── Rechts: Send-Button bei Text-Eingabe

5. KATEGORIEN-LISTEN (pro Kategorie)
   └── Kategorie-Block:
       ├── Kategorie-Header:
       │   ├── Icon (optional): 20px, onSurfaceVariant
       │   ├── Titel: labelLarge, bold, primary
       │   └── Optional: Trenn-Linie (NEIN! Nur Spacing)
       └── Items (spacing 4-8px):
           └── Einkaufs-Item:
               ├── Hoehe: ~48px
               ├── Checkbox: 20x20, rounded-full
               │   Unchecked: outlineVariant Border
               │   Checked: primary, check Icon
               ├── Text: bodyMedium, onSurface
               │   Checked: Durchgestrichen, onSurfaceVariant
               ├── Menge (rechts): labelSmall, onSurfaceVariant
               └── Swipe-to-Delete oder Delete-Icon

6. VORRATSKAMMER-LINK (unten)
   ├── Container: surfaceContainerLow, radiusDefault
   ├── Layout: Icon + Text + Chevron
   └── Text: "Vorratskammer", titleMedium
```

### 9.5 Vorratskammer (Pantry)

**Referenz-Mockup:** `pantry_dark/screen.png`

```
ScrollView (vertikal):

1. HEADER
   ├── Titel: "Vorratskammer: Inventar", headlineLarge, extrabold
   └── Untertitel: bodySmall, onSurfaceVariant
       "Behalte deinen Vorrat im Auge"

2. QUICK ALERTS (konditionell)
   └── Alert-Items (vertikal):
       └── Alert:
           ├── Icon: warning/schedule, secondaryContainer Hintergrund (rounded-full, 32x32)
           ├── Status-Label: labelSmall, UPPERCASE
           │   "Low Stock" → secondary, "Expiring Soon" → error
           ├── Item-Name: titleSmall, bold
           └── Hintergrund: surfaceContainerHigh mit leichtem secondaryContainer-Tint

3. KATEGORIE-SEKTIONEN
   └── Kategorie-Block:
       ├── Header: titleMedium, bold, onSurface
       │   Icon links (z.B. grain, egg, etc.)
       └── Items (spacing 8px):
           └── Pantry-Item:
               ├── Container: surfaceContainerHigh, radiusDefault
               │   ODER: surfaceContainerLowest fuer Alternierung
               ├── Padding: 16px
               ├── Layout: [Icon/Avatar | Name+Details | Menge | Actions]
               ├── Icon/Avatar: 48x48, rounded-full
               │   Bild oder Kategorie-Icon auf surfaceContainerHighest
               ├── Name: titleSmall, bold
               ├── Details: bodySmall, onSurfaceVariant
               │   Ablaufdatum, letzte Nutzung
               ├── Menge: titleSmall, bold, rechts
               │   Einheit: labelSmall, onSurfaceVariant
               └── Progress-Bar (optional):
                   Hoehe: 4px, primary, rounded-full

4. ADD-BUTTON (unten)
   ├── Primary Gradient, rounded-full
   ├── Icon: add + "Artikel hinzufuegen"
   └── Volle Breite oder rechts-ausgerichtet
```

### 9.6 Sprachassistent

**Referenz-Mockups:** `sprachassistent_h_rt_zu/screen.png`, `sprachassistent_ergebnis/screen.png`

```
OVERLAY / BOTTOM SHEET:

1. LISTENING-ZUSTAND
   ├── Hintergrund: surface mit Glassmorphism-Blur des darunterliegenden Screens
   ├── Datum/Kontext: headlineMedium, Plus Jakarta Sans
   │   Text: "Montag, 12. Mai"
   ├── Waveform-Visualisierung:
   │   Vertikale Balken, primary Farbe, animiert
   │   Hoehe variiert (Audio-Pegel)
   ├── Status-Label: labelLarge, onSurfaceVariant
   │   "LISTENING..."
   └── Transkript-Anzeige:
       bodyLarge, onSurface, zentriert
       Live-Update waehrend Spracheingabe
       Text in Anfuehrungszeichen

2. ERGEBNIS-ZUSTAND (DraggableScrollableSheet)
   ├── Header: headlineLarge (32px), extrabold
   │   "Aktionen bestaetigt"
   ├── Bestaetigung-Icon: 48x48, primary, check_circle
   └── Aktions-Liste (spacing 16px):
       └── Aktion (je):
           ├── Status-Icon: 24x24, rounded-full
           │   primary bg + check (Erfolg)
           ├── Typ-Label: labelSmall, UPPERCASE, primary
           │   "EVENT ERSTELLT" / "TODO ERSTELLT" / "EINKAUFSLISTE"
           ├── Beschreibung: titleSmall, onSurface
           └── Meta: bodySmall, onSurfaceVariant

   ├── Primaer-Button: "Fertig"
   │   Primary Gradient, volle Breite, rounded-full
   └── Sekundaer-Link: "Rueckgaengig machen"
       Text-only, bodyMedium, onSurfaceVariant, zentriert
```

### 9.7 Settings-Screen

```
ScrollView (vertikal):

1. HEADER
   ├── Titel: headlineLarge, extrabold
   └── Optional: Avatar + Familien-Info

2. SEKTIONEN (Tonal Layering)
   └── Sektion:
       ├── Sektion-Titel: labelMedium, UPPERCASE, primary, tracking-wide
       ├── Container: surfaceContainerHigh, radiusLarge
       └── Items:
           └── Setting-Zeile:
               ├── Icon: 24px, onSurfaceVariant
               ├── Label: bodyLarge, onSurface
               ├── Wert/Control (rechts): Switch, Dropdown, Text
               └── Trennung: spacing3 (12px), KEIN Divider
```

---

## 10. Animationen & Transitions

### Allgemeine Regeln

| Aktion | Duration | Curve |
|--------|----------|-------|
| Hover/Focus | 200ms | ease-in-out |
| Press (scale) | 100ms | ease-out |
| Screen-Wechsel | 0ms | Keine Transition (Instant, wie aktuell) |
| Bottom-Sheet oeffnen | 300ms | ease-out |
| Karten-Expansion | 200ms | ease-in-out |

### Spezifische Animationen

- **Nav-Item aktiv:** Background-Pille fadet ein (200ms)
- **Todo-Check:** Checkbox fuellet sich, Text wird durchgestrichen (150ms)
- **FAB Press:** scale(0.95) → scale(1.0) (100ms)
- **Voice Listening:** Pulsierender Ring um FAB (1s loop, ease-in-out)
- **Karten-Hover:** Hintergrund-Farbe wechselt sanft (200ms)

---

## 11. Implementierungs-Strategie

### Betroffene Dateien (Flutter)

| Aufgabe | Datei(en) |
|---------|-----------|
| Farb-Tokens aktualisieren | `flutter/lib/core/theme/colors.dart` |
| Theme-Setup (nur Dark) | `flutter/lib/core/theme/app_theme.dart` |
| Bottom Navigation redesignen | `flutter/lib/app/app_shell.dart` |
| Dashboard/Heute redesignen | `flutter/lib/features/today/presentation/today_screen.dart` |
| Kalender redesignen | `flutter/lib/features/calendar/presentation/calendar_screen.dart` |
| Essensplanung redesignen | `flutter/lib/features/meals/presentation/week_plan_screen.dart` |
| Einkaufsliste redesignen | `flutter/lib/features/shopping/presentation/shopping_list_screen.dart` |
| Vorratskammer redesignen | `flutter/lib/features/pantry/presentation/pantry_screen.dart` |
| Voice FAB + Sprach-Sheet redesignen | `flutter/lib/app/app_shell.dart` (`_FamilienherdVoiceFAB`, `_VoiceCommandSheet`), `flutter/lib/core/speech/` |
| Shared Widgets (Karten, etc.) | `flutter/lib/core/widgets/` (ggf. neue Dateien) |

### Reihenfolge

1. **Theme & Tokens** — `colors.dart` + `app_theme.dart` aktualisieren
2. **Navigation** — `app_shell.dart` mit Glassmorphism-NavBar + Voice FAB
3. **Dashboard** — `today_screen.dart` komplett nach Mockup
4. **Kalender** — `calendar_screen.dart` nach Mockup
5. **Essensplanung** — `week_plan_screen.dart` nach Mockup
6. **Einkaufsliste** — `shopping_list_screen.dart` nach Mockup
7. **Vorratskammer** — `pantry_screen.dart` nach Mockup
8. **Sprachassistent** — `app_shell.dart` Bottom-Sheet (`_VoiceCommandSheet`) + `core/speech/`

### Regeln fuer Implementierer

1. **KEIN reines Weiss (#FFFFFF)** — Immer `onSurface` (#E5E2DE) verwenden
2. **KEIN reines Schwarz (#000000)** — Immer `surface` (#131312) verwenden
3. **KEINE 1px Borders** fuer Sektions-Trennung — Nur Hintergrundfarb-Wechsel
4. **KEINE Standard-Divider** zwischen Listen-Items — Spacing verwenden
5. **KEINE Standard Material Elevation** (Level 1,2,3) — Nur Tonal Layering
6. **KEINE Drop-Shadows** — Nur Ambient Glow oder gar kein Shadow
7. **Mindestens 16px Border-Radius** auf allem
8. **Plus Jakarta Sans** fuer Headlines, **Inter** fuer Body
9. **Gradient-Buttons** fuer primaere Aktionen, niemals flache Primary-Farbe
10. **Glassmorphism** fuer Bottom-Nav und schwebende Overlays

---

## 12. Verifizierung

Nach der Implementierung sollte jeder Screen gegen das entsprechende Mockup geprueft werden:

| Screen | Mockup-Referenz |
|--------|-----------------|
| Dashboard | `dashboard_dark_kindred/screen.png` |
| Kalender | `kalender_dark_kindred/screen.png` |
| Essensplanung | `essen_dark_kindred/screen.png` |
| Einkaufsliste | `einkauf_dark_kindred/screen.png` |
| Vorratskammer | `pantry_dark/screen.png` |
| Sprachassistent (Listening) | `sprachassistent_h_rt_zu/screen.png` |
| Sprachassistent (Ergebnis) | `sprachassistent_ergebnis/screen.png` |

**Pruef-Kriterien:**
- Farbwerte stimmen mit Token-Tabelle ueberein
- Keine sichtbaren 1px-Borders
- Typografie-Hierarchie (max 3 Ebenen pro Karte)
- Gradient-Buttons statt flacher Buttons
- Glassmorphism auf Navigation
- Korrekte Spacing-Werte
- Kein reines Weiss oder Schwarz sichtbar
