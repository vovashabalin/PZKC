from __future__ import annotations

import psycopg
from psycopg.rows import dict_row

from mywebapp.config import AppConfig


def connect(config: AppConfig) -> psycopg.Connection:
    """Open a PostgreSQL connection using the application configuration."""
    db = config.database
    return psycopg.connect(
        host=db.host,
        port=db.port,
        dbname=db.name,
        user=db.user,
        password=db.password,
        row_factory=dict_row,
        connect_timeout=3,
    )
