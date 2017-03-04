#!/bin/sh -ex
pip --cache-dir /tmp/pip-cache install -r requirements.txt
mkdocs serve
