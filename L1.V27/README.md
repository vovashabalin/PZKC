# Лабораторна робота №1 — розгортання Web-сервісу з автоматизацією

Рішення для **варіанта 27**. На одній Ubuntu VM розгортаються застосунок `mywebapp`, PostgreSQL, Nginx reverse proxy та systemd socket activation.

## Варіант

Для `N = 27`:

| Формула | Розрахунок | Результат |
|---|---|---|
| `V2 = (N % 2) + 1` | `(27 % 2) + 1 = 2` | конфігурація через файл, PostgreSQL |
| `V3 = (N % 3) + 1` | `(27 % 3) + 1 = 1` | Notes Service |
| `V5 = (N % 5) + 1` | `(27 % 5) + 1 = 3` | порт 3000 |

Реалізований сервіс зберігає текстові нотатки у PostgreSQL. Nginx слухає порт `80`, застосунок — лише `127.0.0.1:3000`, PostgreSQL — лише `127.0.0.1:5432`.

```text
Клієнт → Nginx :80 → mywebapp :3000 → PostgreSQL :5432
```

## Структура

```text
app/                    код Flask-застосунку і міграція БД
deploy/install.sh       єдина точка входу автоматизації
deploy/variant.env      параметри варіанта: адреси і порти
deploy/systemd/         systemd service і socket unit
deploy/nginx/           reverse proxy конфігурація
deploy/sudoers/         обмежені права користувача operator
deploy/verify.sh        перевірка після встановлення
tests/                  unit-тести HTTP-маршрутів
docs/                   checklist відповідності вимогам
```

## Вимоги до VM

- офіційний образ **Ubuntu Server 24.04 LTS**;
- 2 vCPU, 2 GB RAM, 20 GB диска;
- стандартна автоматична розбивка диска;
- тимчасовий користувач, створений під час установки Ubuntu. Після розгортання він буде заблокований відповідно до умови лабораторної.

На VM можна увійти через Console VirtualBox/VMware або SSH. До розгортання використовується тимчасовий користувач, створений під час установки Ubuntu. Після розгортання використовуються облікові записи, створені скриптом.

| Користувач | Початковий пароль | Призначення |
|---|---|---|
| `student` | `12345678` | робота з проєктом; доступна ескалація через `sudo` |
| `teacher` | `12345678` | перевірка; доступна ескалація через `sudo` |
| `operator` | `12345678` | обмежене керування застосунком і Nginx |
| `app` | вхід заборонений | системний користувач застосунку |

Для `student`, `teacher` і `operator` система вимагатиме змінити пароль при першому вході.

## Розгортання

### 1. Отримати код

Клонуйте **реальний** репозиторій і перейдіть саме в каталог цієї лабораторної:

```bash
git clone https://github.com/vovashabalin/PZKC.git
cd PZKC/L1.V27
```

### 2. Запустити автоматизацію

Спочатку подивіться ім’я поточного тимчасового користувача VM:

```bash
whoami
```

Потім виконайте:

```bash
chmod +x deploy/install.sh deploy/verify.sh
sudo ./deploy/install.sh --default-user <ім'я_з_whoami>
sudo ./deploy/verify.sh
```

Приклад для користувача `vboxuser`:

```bash
sudo ./deploy/install.sh --default-user vboxuser
sudo ./deploy/verify.sh
```

Параметр `--default-user` обов’язковий. Вказаний користувач буде заблокований наприкінці встановлення, тому перед запуском переконайтеся, що використовуєте правильне ім’я.

За потреби пароль PostgreSQL можна задати перед стартом:

```bash
sudo DB_PASSWORD='my_secure_password_27' ./deploy/install.sh --default-user vboxuser
```

Дозволені символи пароля: латинські літери, цифри та `. _ % + = , @ : -`.

Скрипт встановлює пакети, створює користувачів і БД, розгортає конфігурацію, виконує міграцію перед запуском сервісу, налаштовує Nginx та створює `/home/student/gradebook` із числом `27`.

## Systemd та operator

Після встановлення створюються:

```text
/etc/systemd/system/mywebapp.service
/etc/systemd/system/mywebapp.socket
```

Socket unit слухає `127.0.0.1:3000`. При першому запиті systemd запускає Gunicorn, а `ExecStartPre` спочатку виконує міграцію БД.

Користувач `operator` може виконувати лише:

```bash
sudo /usr/local/sbin/mywebapp-control start
sudo /usr/local/sbin/mywebapp-control stop
sudo /usr/local/sbin/mywebapp-control restart
sudo /usr/local/sbin/mywebapp-control status
sudo systemctl reload nginx.service
```

## API

Бізнес-ендпоінти обробляють `Accept: application/json` і `Accept: text/html`. Для HTML списки виводяться таблицями. Кореневий endpoint повертає лише HTML.

| Метод і шлях | Опис |
|---|---|
| `GET /` | список бізнес-ендпоінтів, тільки HTML |
| `GET /notes` | список нотаток: `id`, `title` |
| `POST /notes` | створити нотатку з `title`, `content` |
| `GET /notes/<id>` | повний вміст нотатки |
| `GET /health/alive` | локальна перевірка: завжди `200 OK` |
| `GET /health/ready` | локальна перевірка підключення до PostgreSQL |

Через Nginx доступні лише `/`, `/notes` і `/notes/<id>`. Health-check-и доступні тільки на VM через `127.0.0.1:3000`.

### Приклади

```bash
curl -i -H 'Accept: text/html' http://<VM-IP>/
curl -i -H 'Accept: application/json' http://<VM-IP>/notes

curl -i -X POST http://<VM-IP>/notes \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{"title":"Перша нотатка","content":"Перевірка лабораторної"}'

curl -i -H 'Accept: application/json' http://<VM-IP>/notes/1
curl -i http://127.0.0.1:3000/health/alive
curl -i http://127.0.0.1:3000/health/ready
```

## Локальний запуск і тести

Для розробки без systemd і Nginx потрібен локально встановлений PostgreSQL:

```bash
cd app
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp config.dev.toml.example config.dev.toml
# Відредагувати password у config.dev.toml
python migrate.py --config config.dev.toml
python run_dev.py --config config.dev.toml
```

Unit-тести маршрутів без реальної БД:

```bash
PYTHONPATH=app python3 -m unittest discover -s tests -v
```

## Перевірка вимог

Після розгортання виконайте:

```bash
sudo ./deploy/verify.sh
```

Скрипт перевіряє systemd socket/service, Nginx, доступність API через reverse proxy, локальні health-check-и, локальний listener PostgreSQL і файл `gradebook`.

Детальна таблиця відповідності вимогам міститься у [`docs/requirements-checklist.md`](docs/requirements-checklist.md).
