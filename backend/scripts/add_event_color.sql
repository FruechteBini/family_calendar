-- Optional: Terminfarbe (#RRGGBB), unabhängig von der Kategorie
ALTER TABLE events ADD COLUMN IF NOT EXISTS color VARCHAR(7);
