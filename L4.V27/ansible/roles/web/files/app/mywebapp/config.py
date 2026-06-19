from __future__ import annotations

import os
import tomllib
from dataclasses import dataclass
from pathlib import Path


class ConfigError(RuntimeError):
    """Raised when the application configuration is incomplete or invalid."""


@dataclass(frozen=True)
class DatabaseConfig:
    host: str
    port: int
    name: str
    user: str
    password: str


@dataclass(frozen=True)
class AppConfig:
    host: str
    port: int
    database: DatabaseConfig


def _required(mapping: dict, key: str) -> object:
    value = mapping.get(key)
    if value in (None, ""):
        raise ConfigError(f"Missing required configuration key: {key}")
    return value


def _database_password(section: dict) -> str:
    """Read a literal password or resolve it via an explicitly named variable.

    Lab 1 writes a protected literal password to /etc/mywebapp/config.toml.
    Container and IaC deployments use password_env so that a secret is not
    committed to Git.
    """
    password = section.get("password")
    if password not in (None, ""):
        return str(password)

    password_env = section.get("password_env")
    if not isinstance(password_env, str) or not password_env:
        raise ConfigError("database.password or database.password_env is required")

    value = os.environ.get(password_env)
    if not value:
        raise ConfigError(f"Environment variable {password_env} is not set")
    return value


def _port(value: object, key: str) -> int:
    try:
        port = int(value)
    except (TypeError, ValueError) as exc:
        raise ConfigError(f"{key} must be an integer") from exc
    if not 1 <= port <= 65535:
        raise ConfigError(f"{key} must be between 1 and 65535")
    return port


def load_config(path: str | Path) -> AppConfig:
    """Load TOML configuration from *path*.

    The application itself permits a database hostname for container and
    two-node deployments. Network exposure is restricted by the deployment
    configuration: Lab 1 binds PostgreSQL to 127.0.0.1, while Lab 4 limits
    PostgreSQL with pg_hba.conf and the dedicated libvirt network.
    """
    config_path = Path(path)
    try:
        with config_path.open("rb") as config_file:
            data = tomllib.load(config_file)
    except FileNotFoundError as exc:
        raise ConfigError(f"Configuration file was not found: {config_path}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise ConfigError(f"Invalid TOML in configuration file: {config_path}") from exc

    try:
        app_section = data["app"]
        database_section = data["database"]
    except KeyError as exc:
        raise ConfigError(f"Missing configuration section: {exc.args[0]}") from exc

    host = str(_required(app_section, "host"))
    port = _port(_required(app_section, "port"), "app.port")

    database = DatabaseConfig(
        host=str(_required(database_section, "host")),
        port=_port(_required(database_section, "port"), "database.port"),
        name=str(_required(database_section, "name")),
        user=str(_required(database_section, "user")),
        password=_database_password(database_section),
    )

    return AppConfig(host=host, port=port, database=database)
