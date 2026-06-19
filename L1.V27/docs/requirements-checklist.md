# Відповідність вимогам лабораторної

| Вимога | Реалізація |
|---|---|
| Всі компоненти на одній VM | `mywebapp`, PostgreSQL та Nginx встановлюються `deploy/install.sh` |
| Nginx на `0.0.0.0:80` | `deploy/nginx/mywebapp.conf` |
| Web app на localhost і порту варіанта | `deploy/systemd/mywebapp.socket`: `127.0.0.1:3000` |
| БД тільки на VM | `install.sh` змінює `listen_addresses` PostgreSQL на `127.0.0.1` |
| Веб-застосунок | Notes Service: `GET /notes`, `POST /notes`, `GET /notes/<id>` |
| Конфігурація через файл | `/etc/mywebapp/config.toml` |
| PostgreSQL | пакет `postgresql`, роль і БД `mywebapp` |
| Health checks | `/health/alive`, `/health/ready` |
| HTML і JSON | content negotiation на бізнес-ендпоінтах |
| Кореневий HTML endpoint | `/`, тільки `Accept: text/html` |
| Міграція | `app/migrate.py`, запускається як `ExecStartPre` |
| systemd service | `/etc/systemd/system/mywebapp.service` |
| Socket activation | `/etc/systemd/system/mywebapp.socket`; Gunicorn приймає socket від systemd |
| Користувачі | `student`, `teacher`, `operator`, `app` |
| Обмежений operator | sudoers + `/usr/local/sbin/mywebapp-control` |
| Автоматизація | одна точка входу: `deploy/install.sh` |
| gradebook | `/home/student/gradebook` з `27` |
| Блокування дефолтного користувача | обов’язковий параметр `--default-user USER` |
| README | `README.md` у корені PZKC веде до `L1.V27/README.md` |
