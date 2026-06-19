from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from mywebapp.config import load_config


class ConfigTests(unittest.TestCase):
    def test_password_can_be_provided_by_environment_for_container_deployment(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_path = Path(temporary_directory) / "config.toml"
            config_path.write_text(
                "[app]\nhost = '0.0.0.0'\nport = 3000\n\n"
                "[database]\nhost = 'db'\nport = 5432\n"
                "name = 'mywebapp'\nuser = 'mywebapp'\npassword_env = 'TEST_DB_PASSWORD'\n",
                encoding="utf-8",
            )
            with patch.dict(os.environ, {"TEST_DB_PASSWORD": "temporary-password"}):
                config = load_config(config_path)

        self.assertEqual(config.database.host, "db")
        self.assertEqual(config.database.password, "temporary-password")


if __name__ == "__main__":
    unittest.main()
