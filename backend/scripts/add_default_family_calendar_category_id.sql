-- Older DBs: Family.default_family_calendar_category_id
ALTER TABLE families
ADD COLUMN IF NOT EXISTS default_family_calendar_category_id INTEGER
REFERENCES categories(id) ON DELETE SET NULL;
