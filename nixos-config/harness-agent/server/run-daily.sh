#!/usr/bin/env bash
set -euo pipefail

base=/root/professor_ot
agent="$base/agent"
workspace="$agent/projects/professor-it-marketing"
prompt="$workspace/MARKETING/AGENT/DAILY-PROMPT.md"
log_dir="$agent/logs"

mkdir -p "$log_dir"
log="$log_dir/daily-$(date +%F).log"

exec /usr/bin/docker run --rm \
  --name professorit-marketing-agent-daily \
  -e DSH_HOME=/root/.dsh \
  -e DSH_AGENTS_HOME=/root/.agents \
  -v "$base:$base" \
  -v "$agent/dsh-home:/root/.dsh" \
  -v "$workspace/MARKETING/AGENT/skills:/root/.agents/skills:ro" \
  -w "$workspace" \
  professorit-harness-agent:0.1.5 \
  sh -lc 'dsh --profile headless "$(cat MARKETING/AGENT/DAILY-PROMPT.md)"' \
  >>"$log" 2>&1
