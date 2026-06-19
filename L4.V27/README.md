# Лабораторна робота №4 — IaC Terraform + Ansible, варіант 27

Робота розгортає застосунок із `L1.V27` на двох Ubuntu 24.04 Cloud VM у
окремій libvirt NAT-мережі:

- `worker` — nginx на `0.0.0.0:80`, Gunicorn на `127.0.0.1:3000`;
- `db` — PostgreSQL на `192.168.124.20:5432`.

`worker` має адресу `192.168.124.10`. PostgreSQL слухає тільки адресу db VM,
а `pg_hba.conf` дозволяє застосунковому користувачу лише `worker` і `db`.

## Передумови на KVM/QEMU хості

Встанови Terraform, libvirt/QEMU, `genisoimage`, Ansible і колекцію PostgreSQL:

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients genisoimage ansible
sudo usermod -aG libvirt "$USER"
# Вийди із сесії та увійди знову після зміни групи.
ansible-galaxy collection install -r L4.V27/ansible/collections.yml
```

Згенеруй або використай SSH key, який буде додано користувачу `ansible` через
cloud-init:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```

## Підняти дві VM одним Terraform apply

```bash
cd L4.V27/terraform
terraform init
terraform apply
```

Terraform завантажує офіційний Ubuntu 24.04 cloud image, створює приватну NAT
мережу, cloud-init ISO для обох VM і два окремі root-диски. IP адреси не
вгадуються, а оголошені у `outputs.tf`.

## Налаштувати VM одним Ansible playbook

```bash
cd ../ansible
export MYWEBAPP_DB_PASSWORD='обери_довгий_пароль_без_пробілів'
ansible-playbook site.yml --private-key ~/.ssh/id_ed25519
ansible-playbook verify.yml --private-key ~/.ssh/id_ed25519
```

Динамічний `inventory.py` читає `terraform output -json` і повертає групи
`workers` та `db`. Повторний запуск `site.yml` не повинен змінювати конфігурацію,
коли стан уже відповідає ролям. Міграція БД є ідемпотентною та виконується через
`ExecStartPre` перед запуском `mywebapp`.

## Користувачі

- `ansible` створюється cloud-init на обох VM, має SSH key і passwordless sudo;
- `teacher` створюється Ansible на обох VM, пароль `12345678`, sudo із паролем;
- `app` є системним користувачем тільки на worker;
- `operator` є тільки на worker, пароль `12345678`, має лише потрібні `systemctl`
  команди без пароля;
- `student` створюється мінімально тільки для вимоги `/home/student/gradebook`;
  файл містить `27`.

## Перевірки

```bash
curl -H 'Accept: text/html' http://192.168.124.10/
curl -H 'Accept: application/json' http://192.168.124.10/notes
ssh ansible@192.168.124.10 'curl -s http://127.0.0.1:3000/health/ready'
ssh ansible@192.168.124.20 'ss -ltn | grep 5432'
```

Не додавай у Git `terraform.tfvars`, `*.tfstate` або пароль бази даних.
