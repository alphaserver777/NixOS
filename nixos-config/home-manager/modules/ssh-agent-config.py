"""Задача 030: подключить управляемое правило, сохранив серверы LazySSH."""
import os
from pathlib import Path
import sys
import tempfile


def atomic_write(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(data)
            stream.flush()
            os.fchmod(stream.fileno(), 0o600)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


home = Path.home()
ssh = home / ".ssh"
ssh.mkdir(mode=0o700, exist_ok=True)
config = ssh / "config"
fragment = ssh / "nixos-agent.conf"
source = Path(sys.argv[1])
marker = b"# BEGIN NIXOS SSH AGENT (task 030)"
block = (b"\n" + marker + b"\nMatch all\n"
         b"Include ~/.ssh/nixos-agent.conf\n"
         b"# END NIXOS SSH AGENT (task 030)\n")

if config.is_symlink():
    raise RuntimeError("Основной файл SSH уже управляется другой конфигурацией")
if fragment.exists() and not fragment.is_symlink():
    raise RuntimeError("nixos-agent.conf уже существует как пользовательский файл")
original = config.read_bytes() if config.exists() else b""
if marker not in original:
    state = Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")) / "ssh-agent-client"
    state.mkdir(parents=True, mode=0o700, exist_ok=True)
    os.chmod(state, 0o700)
    backup = state / "config.before"
    if not backup.exists():
        atomic_write(backup, original)

# Замена ссылки сохраняет обновляемый фрагмент под управлением Nix.
temporary_link = ssh / ".nixos-agent.conf.new"
temporary_link.unlink(missing_ok=True)
temporary_link.symlink_to(source)
os.replace(temporary_link, fragment)
if marker not in original:
    atomic_write(config, original + block)
