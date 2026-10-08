#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "${script_dir}/.." && pwd)"

if [[ -x "${repo_dir}/.venv/bin/python" ]]; then
  python_bin="${repo_dir}/.venv/bin/python"
else
  python_bin="python3"
fi

exec "${python_bin}" "${script_dir}/codex_rename_threads.py" "$@"
