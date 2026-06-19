from __future__ import annotations

import os
from datetime import datetime
from html import escape
from typing import Any

import psycopg
from flask import Flask, Response, jsonify, request

from mywebapp.config import ConfigError, load_config
from mywebapp.db import connect

JSON = "application/json"
HTML = "text/html"


def html_page(title: str, body: str) -> str:
    return (
        "<!doctype html>\n"
        '<html lang="uk">\n'
        '<head><meta charset="utf-8"><title>'
        f"{escape(title)}"
        "</title></head>\n"
        "<body>\n"
        f"<h1>{escape(title)}</h1>\n"
        f"{body}\n"
        "</body>\n"
        "</html>"
    )


def created_at_to_string(value: Any) -> str:
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def serialise_note(note: dict[str, Any], include_content: bool) -> dict[str, Any]:
    result: dict[str, Any] = {
        "id": note["id"],
        "title": note["title"],
        "created_at": created_at_to_string(note["created_at"]),
    }
    if include_content:
        result["content"] = note["content"]
    return result


def preferred_representation() -> str | None:
    return request.accept_mimetypes.best_match([JSON, HTML])


def error_response(message: str, status: int) -> Response:
    preferred = preferred_representation()
    if preferred == HTML:
        return Response(
            html_page("Помилка", f"<p>{escape(message)}</p>"),
            status=status,
            mimetype=HTML,
        )
    if preferred == JSON:
        return jsonify(error=message), status
    return Response(
        "Not acceptable. Use Accept: application/json or text/html.\n",
        status=406,
        mimetype="text/plain",
    )


def representation_response(
    json_data: Any,
    html_body: str,
    *,
    title: str,
    status: int = 200,
) -> Response:
    preferred = preferred_representation()
    if preferred == HTML:
        return Response(html_page(title, html_body), status=status, mimetype=HTML)
    if preferred == JSON:
        return jsonify(json_data), status
    return Response(
        "Not acceptable. Use Accept: application/json or text/html.\n",
        status=406,
        mimetype="text/plain",
    )


def notes_table(notes: list[dict[str, Any]]) -> str:
    rows = "".join(
        f"<tr><td>{note['id']}</td><td>{escape(note['title'])}</td></tr>" for note in notes
    )
    return (
        '<table border="1">'
        "<thead><tr><th>ID</th><th>Назва</th></tr></thead>"
        f"<tbody>{rows}</tbody></table>"
    )


def note_details(note: dict[str, Any]) -> str:
    return (
        '<table border="1">'
        f"<tr><th>ID</th><td>{note['id']}</td></tr>"
        f"<tr><th>Назва</th><td>{escape(note['title'])}</td></tr>"
        f"<tr><th>Створено</th><td>{escape(created_at_to_string(note['created_at']))}</td></tr>"
        f"<tr><th>Вміст</th><td>{escape(note['content'])}</td></tr>"
        "</table>"
    )


def request_payload() -> tuple[str, str] | None:
    if request.is_json:
        payload = request.get_json(silent=True)
    else:
        payload = request.form.to_dict()

    if not isinstance(payload, dict):
        return None

    title = payload.get("title")
    content = payload.get("content")
    if not isinstance(title, str) or not isinstance(content, str):
        return None

    title = title.strip()
    if not title or len(title) > 200:
        return None
    return title, content


def create_app(config_path: str | None = None) -> Flask:
    app = Flask(__name__)
    selected_config_path = config_path or os.environ.get("CONFIG_PATH", "/etc/mywebapp/config.toml")

    try:
        config = load_config(selected_config_path)
    except ConfigError as exc:
        # The app can still start, while /health/ready will clearly report that it
        # cannot serve requests. In production systemd normally catches this first
        # during ExecStartPre migration.
        config = None
        config_error = str(exc)
    else:
        config_error = None

    @app.get("/health/alive")
    def health_alive() -> Response:
        return Response("OK", status=200, mimetype="text/plain")

    @app.get("/health/ready")
    def health_ready() -> Response:
        if config is None:
            return Response(
                f"configuration error: {config_error}\n",
                status=500,
                mimetype="text/plain",
            )
        try:
            with connect(config) as connection:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
                    cursor.fetchone()
        except psycopg.Error:
            return Response("database is unavailable\n", status=500, mimetype="text/plain")
        return Response("OK", status=200, mimetype="text/plain")

    @app.get("/")
    def index() -> Response:
        if request.accept_mimetypes[HTML] <= 0:
            return Response(
                "Only Accept: text/html is supported for /.\n",
                status=406,
                mimetype="text/plain",
            )
        body = (
            "<p>Доступні ендпоінти бізнес-логіки:</p>"
            "<ul>"
            "<li>GET /notes</li>"
            "<li>POST /notes</li>"
            "<li>GET /notes/&lt;id&gt;</li>"
            "</ul>"
        )
        return Response(html_page("mywebapp — Notes Service", body), mimetype=HTML)

    @app.get("/notes")
    def list_notes() -> Response:
        if config is None:
            return error_response("Сервіс не налаштований: база даних недоступна.", 500)
        try:
            with connect(config) as connection:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT id, title, created_at, content FROM notes ORDER BY id")
                    notes = cursor.fetchall()
        except psycopg.Error:
            return error_response("Не вдалося отримати дані з бази даних.", 500)

        json_notes = [{"id": note["id"], "title": note["title"]} for note in notes]
        return representation_response(json_notes, notes_table(notes), title="Список нотаток")

    @app.post("/notes")
    def create_note() -> Response:
        if config is None:
            return error_response("Сервіс не налаштований: база даних недоступна.", 500)
        payload = request_payload()
        if payload is None:
            return error_response(
                "Потрібні поля title (1–200 символів) і content у JSON або form data.",
                400,
            )
        title, content = payload
        try:
            with connect(config) as connection:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        INSERT INTO notes (title, content)
                        VALUES (%s, %s)
                        RETURNING id, title, content, created_at
                        """,
                        (title, content),
                    )
                    note = cursor.fetchone()
                connection.commit()
        except psycopg.Error:
            return error_response("Не вдалося зберегти нотатку у базі даних.", 500)

        assert note is not None
        json_note = serialise_note(note, include_content=True)
        return representation_response(
            json_note,
            note_details(note),
            title="Нотатку створено",
            status=201,
        )

    @app.get("/notes/<int:note_id>")
    def get_note(note_id: int) -> Response:
        if config is None:
            return error_response("Сервіс не налаштований: база даних недоступна.", 500)
        try:
            with connect(config) as connection:
                with connection.cursor() as cursor:
                    cursor.execute(
                        "SELECT id, title, content, created_at FROM notes WHERE id = %s",
                        (note_id,),
                    )
                    note = cursor.fetchone()
        except psycopg.Error:
            return error_response("Не вдалося отримати дані з бази даних.", 500)

        if note is None:
            return error_response("Нотатку не знайдено.", 404)
        return representation_response(
            serialise_note(note, include_content=True),
            note_details(note),
            title="Нотатка",
        )

    return app
