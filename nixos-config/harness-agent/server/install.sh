#!/usr/bin/env bash
set -euo pipefail

base=/root/professor_ot
agent="$base/agent"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -d -m 0700 /etc/professorit-agent
install -d -m 0700 "$agent/dsh-home" "$agent/dsh-home/skills"
install -d -m 0750 "$agent/bin" "$agent/logs" "$agent/projects"

docker build -t professorit-harness-agent:0.1.5 "$script_dir"

install -m 0750 "$script_dir/run-daily.sh" "$agent/bin/run-daily.sh"
install -m 0644 "$script_dir/professorit-marketing-agent-bot.service" /etc/systemd/system/
install -m 0644 "$script_dir/professorit-marketing-agent-daily.service" /etc/systemd/system/
install -m 0644 "$script_dir/professorit-marketing-agent-daily.timer" /etc/systemd/system/
install -d -m 0750 "$agent/dsh-home/profiles/headless"
install -m 0644 "$script_dir/headless.cordis.patch.yml" \
  "$agent/dsh-home/profiles/headless/cordis.patch.yml"

if [[ ! -f /etc/professorit-agent/telegram.env ]]; then
  install -m 0600 "$script_dir/telegram.env.example" /etc/professorit-agent/telegram.env
fi

systemctl daemon-reload

echo "Среда установлена. Перед запуском Telegram заполните:"
echo "  /etc/professorit-agent/telegram.env"
echo "Затем выполните:"
echo "  systemctl enable --now professorit-marketing-agent-bot.service"
echo "  systemctl enable --now professorit-marketing-agent-daily.timer"
