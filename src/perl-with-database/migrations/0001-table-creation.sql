CREATE TABLE IF NOT EXISTS activity_log (
    id          SERIAL PRIMARY KEY,
    insertdate  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    username    VARCHAR(255) NOT NULL,
    count       INTEGER NOT NULL DEFAULT 0
);