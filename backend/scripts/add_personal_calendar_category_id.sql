-- One-off / idempotent for older DBs: User.personal_calendar_category_id
ALTER TABLE users
ADD COLUMN IF NOT EXISTS personal_calendar_category_id INTEGER
REFERENCES categories(id) ON DELETE SET NULL;
