# PZKC — лабораторні роботи з DevOps, варіант 27

Репозиторій містить чотири пов’язані лабораторні роботи. У всіх роботах використано
варіант `N = 27`:

```text
V2 = (27 % 2) + 1 = 2  → PostgreSQL і конфігураційний файл
V3 = (27 % 3) + 1 = 1  → Notes Service
V5 = (27 % 5) + 1 = 3  → порт застосунку 3000
```

## Структура

- [L1.V27](L1.V27/README.md) — вебсервіс Notes Service, PostgreSQL, systemd і nginx.
- [L2.V27](L2.V27/README.md) — контейнеризація та запуск через Docker Compose.
- [L3.V27](L3.V27/README.md) — CI/CD, GitHub Actions, GHCR, self-hosted runner і target node.
- [L4.V27](L4.V27/README.md) — Terraform/libvirt, cloud-init та Ansible для двох VM.

## Як додати в GitHub-репозиторій

Архів підготовлений **без зайвої вкладеної папки**. Після розпакування його вміст
має бути скопійований саме в корінь репозиторію `PZKC`, де лежить папка `.git`.
У результаті у корені мають бути `L1.V27`, `L2.V27`, `L3.V27`, `L4.V27` та `.github`.

Для локального репозиторію в Ubuntu:

```bash
cd ~/PZKC
# Після розпакування архіву в ~/Downloads/PZKC_UPLOAD:
cp -a ~/Downloads/PZKC_UPLOAD/. .
git add -A
git commit -m "Add DevOps labs 1-4"
git push
```

Перед копіюванням видаліть старі помилкові папки `LR1_V27`, `LR2_V27`, `LR3_V27`,
`LR4_V27` і `PZKC_augh`, якщо вони залишилися від попередніх завантажень.

Не додавайте у репозиторій паролі, SSH-ключі, `.env`, `terraform.tfvars`, `.tfstate`,
coverage-файли або ZIP-архіви. Ці файли вже виключені через `.gitignore`.
