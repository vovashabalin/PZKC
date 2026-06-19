#!/usr/bin/env python3
"""Dynamic inventory generated from the Terraform state outputs.

Use it only after `terraform apply` completed in ../terraform. It does not
create or scan machines; it reads the two declared static output addresses.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

terraform_dir = Path(__file__).resolve().parents[1] / "terraform"
try:
    result = subprocess.run(
        ["terraform", "output", "-json"],
        cwd=terraform_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    output = json.loads(result.stdout)
    worker_ip = output["worker_ip"]["value"]
    db_ip = output["db_ip"]["value"]
except (FileNotFoundError, subprocess.CalledProcessError, KeyError, json.JSONDecodeError) as exc:
    print(f"Cannot read Terraform outputs: {exc}", file=sys.stderr)
    raise SystemExit(1)

inventory = {
    "_meta": {
        "hostvars": {
            "worker": {"ansible_host": worker_ip, "node_role": "worker"},
            "db": {"ansible_host": db_ip, "node_role": "db"},
        }
    },
    "workers": {"hosts": ["worker"]},
    "db": {"hosts": ["db"]},
}
print(json.dumps(inventory))
