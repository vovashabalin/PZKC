# Лабораторна робота №2 — контейнеризація, варіант 27

Ця директорія містить практичну частину контейнеризації застосунку з `L1.V27`
та відтворювані сценарії дослідницької частини.

## Практична частина

У стек входять три ізольовані сервіси в мережі `mywebapp_private`:

- `nginx` — єдиний сервіс з опублікованим HTTP-портом;
- `app` — Flask/Gunicorn, доступний тільки усередині мережі;
- `db` — PostgreSQL з named volume `mywebapp_postgres_data`.

Підготовка і запуск:

```bash
cd L2.V27
cp .env.example .env
# У .env задай однакові непорожні POSTGRES_PASSWORD і APP_DB_PASSWORD.
docker compose up -d --build --wait
./scripts/compose-smoke-test.sh
```

Для зупинки:

```bash
docker compose down
```

Named volume не видаляється при звичайному `docker compose down`, тому дані
PostgreSQL переживають перезапуск контейнерів і системи. Перевірка `/health/*`
виконується всередині контейнерної мережі; nginx повертає `404` для цих шляхів
зовнішньому клієнту.

## Дослідницька частина

Точні команди, Dockerfile для Python і Go та сценарій DNS-досліду наведено у
[`docs/experiments.md`](docs/experiments.md). Скрипт `measure-build.sh` зберігає
фактичні часи й розміри образів у `results/`, який навмисно не додається в Git.

## Перевірка перед здачею

```bash
docker compose config
docker compose ps
./scripts/compose-smoke-test.sh
```

Не коміть `.env`, `results/` або завантажені копії зовнішніх starter-проєктів.
