from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path
from unittest.mock import patch

from mywebapp.web import create_app


class Cursor:
    def __init__(self, one=None, many=None):
        self.one = one
        self.many = many or []
        self.executed: list[tuple[str, tuple | None]] = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback):
        return False

    def execute(self, query: str, params=None):
        self.executed.append((query, params))

    def fetchone(self):
        return self.one

    def fetchall(self):
        return self.many


class Connection:
    def __init__(self, cursor: Cursor):
        self._cursor = cursor
        self.committed = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback):
        return False

    def cursor(self):
        return self._cursor

    def commit(self):
        self.committed = True


class NotesRoutesTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_path = Path(self.temp_dir.name) / "config.toml"
        self.config_path.write_text(
            '[app]\nhost = "127.0.0.1"\nport = 3000\n\n'
            '[database]\nhost = "127.0.0.1"\nport = 5432\n'
            'name = "test"\nuser = "test"\npassword = "test"\n',
            encoding="utf-8",
        )
        self.app = create_app(str(self.config_path))
        self.client = self.app.test_client()

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_root_requires_html(self):
        response = self.client.get("/", headers={"Accept": "application/json"})
        self.assertEqual(response.status_code, 406)

    def test_root_returns_html(self):
        response = self.client.get("/", headers={"Accept": "text/html"})
        self.assertEqual(response.status_code, 200)
        self.assertIn("Notes Service", response.get_data(as_text=True))

    def test_list_notes_returns_json(self):
        cursor = Cursor(
            many=[
                {
                    "id": 1,
                    "title": "Перша",
                    "content": "Текст",
                    "created_at": datetime(2026, 6, 19, tzinfo=UTC),
                }
            ]
        )
        with patch("mywebapp.web.connect", return_value=Connection(cursor)):
            response = self.client.get("/notes", headers={"Accept": "application/json"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), [{"id": 1, "title": "Перша"}])

    def test_create_note_rejects_missing_content(self):
        response = self.client.post(
            "/notes",
            json={"title": "Без тексту"},
            headers={"Accept": "application/json"},
        )
        self.assertEqual(response.status_code, 400)


if __name__ == "__main__":
    unittest.main()
