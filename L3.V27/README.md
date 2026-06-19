# Лабораторна робота №3 — CI/CD, варіант 27

Лабораторна робота використовує образ застосунку з `L1.V27/app/Dockerfile`.
Всі workflow-файли знаходяться в кореневій `.github/workflows`, оскільки тільки
ця директорія виконується GitHub Actions.

## Що автоматизовано

- `ci.yml`: статичний аналіз Python, shell і YAML; unit-тести з мінімум 40%
  coverage; збереження coverage як artifact для `main`; build та публікація
  образу в GitHub Container Registry;
- `cd.yml`: для анотованого тега повторює gate lint/test/build, а далі запускає
  розгортання тільки на self-hosted runner з label `lab3-runner`;
- `deploy/target-bootstrap.sh`: одноразово готує окрему target VM з Docker,
  Docker Compose, nginx і користувачем `deployer`;
- `scripts/deploy-from-runner.sh` і `scripts/verify-deployment.sh`: передають
  конфіг без комітування секретів і перевіряють deployment через SSH.

## Ручна підготовка

1. Підготуй **дві різні** Ubuntu 24.04 VM: одну для runner, одну для target.
2. На target VM виконай `sudo ./L3.V27/deploy/target-bootstrap.sh`.
3. На runner VM виконай `sudo ./L3.V27/runner/install-runner-dependencies.sh`,
   потім вручну виконай команди, які GitHub покаже під час додавання runner.
4. Додай SSH public key runner-користувача до `/home/deployer/.ssh/authorized_keys`
   target VM.
5. Налаштуй GitHub Secrets і branch protection за
   [`docs/github-configuration.md`](docs/github-configuration.md).
6. Створи анотований тег, наприклад: `git tag -a v0.3.0 -m "Lab 3 release"`,
   `git push origin v0.3.0`. Lightweight tags (`git tag v0.3.0`) навмисно
   відхиляються CD workflow.

## Очікувані image tags

Push до `main`: `latest`, `sha-<full-commit-hash>`.

Анотований тег: `stable`, `<tag>`, `sha-<full-commit-hash>`.

## Що вставити у міні-звіт

Див. окремий Word-документ і `docs/github-configuration.md`. Не підміняй логи
вигаданими: потрібні справжні посилання/скріншоти GitHub Actions після запуску.
