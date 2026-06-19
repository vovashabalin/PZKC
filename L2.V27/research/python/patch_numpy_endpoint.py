#!/usr/bin/env python3
"""Insert an idempotent NumPy endpoint into the downloaded starter project.

The exact source repository is not committed into this lab repository. The
script changes only the local clone in research/work/python and can be reviewed
before execution.
"""

from pathlib import Path

api_path = (
    Path(__file__).resolve().parents[1] / "work" / "python" / "spaceship" / "routers" / "api.py"
)
source = api_path.read_text(encoding="utf-8")
if "matrix_product" in source:
    print("NumPy endpoint already exists.")
    raise SystemExit(0)

endpoint = """\


@router.get("/matrix-product")
def matrix_product() -> dict[str, list[list[float]]]:
    import numpy as np

    matrix_a = np.random.default_rng().random((10, 10))
    matrix_b = np.random.default_rng().random((10, 10))
    product = matrix_a @ matrix_b
    return {
        "matrix_a": matrix_a.tolist(),
        "matrix_b": matrix_b.tolist(),
        "product": product.tolist(),
    }
"""
api_path.write_text(source.rstrip() + endpoint + "\n", encoding="utf-8")
requirements = api_path.parents[2] / "requirements" / "numpy.in"
requirements.write_text("numpy==2.2.6\n", encoding="utf-8")
print(f"Updated {api_path}")
