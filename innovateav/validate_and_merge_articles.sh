#!/usr/bin/env bash
# Wrapper: stage candidates in candidates.json, then gate-merge into articles2.json.
set -euo pipefail
cd "$(dirname "$0")"
exec python3 validate_and_merge_articles.py "$@"
