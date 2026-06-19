#!/usr/bin/env python3
"""Convenience launcher for local development without systemd and nginx."""

import argparse

from mywebapp.config import load_config
from mywebapp.web import create_app

parser = argparse.ArgumentParser()
parser.add_argument("--config", default="config.dev.toml")
args = parser.parse_args()
config = load_config(args.config)
create_app(args.config).run(host=config.host, port=config.port, debug=True)
