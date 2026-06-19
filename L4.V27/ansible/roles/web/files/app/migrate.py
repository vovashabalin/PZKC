#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys

from mywebapp.config import ConfigError, load_config
from mywebapp.db import connect

MIGRATION_SQL = """
CREATE TABLE IF NOT EXISTS notes (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notes_title_not_blank CHECK (char_length(trim(title)) > 0)
);

CREATE INDEX IF NOT EXISTS notes_created_at_idx
    ON notes (created_at DESC);
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create or upgrade mywebapp database schema.")
    parser.add_argument(
        "--config",
        default="/etc/mywebapp/config.toml",
        help="Path to TOML configuration file (default: /etc/mywebapp/config.toml)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        config = load_config(args.config)
        with connect(config) as connection:
            with connection.cursor() as cursor:
                cursor.execute(MIGRATION_SQL)
            connection.commit()
    except (ConfigError, OSError, Exception) as exc:
        # psycopg exceptions inherit from Exception. Keeping a short error is useful
        # in systemd journal while avoiding a stack trace in normal deployment output.
        print(f"Database migration failed: {exc}", file=sys.stderr)
        return 1

    print("Database migration completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
