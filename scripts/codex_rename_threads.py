#!/usr/bin/env python3
"""Interactive renamer for local Codex thread titles.

The script updates both known local title stores:
- ~/.codex/session_index.jsonl
- ~/.codex/state_5.sqlite, table threads.title

It does not rename or delete rollout JSONL dialogue files.
"""

from __future__ import annotations

import json
import os
import shutil
import sqlite3
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


CODEX_HOME = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")).expanduser()
INDEX_PATH = CODEX_HOME / "session_index.jsonl"
STATE_DB_PATH = CODEX_HOME / "state_5.sqlite"
BACKUP_DIR = CODEX_HOME / "rename_backups"


@dataclass(frozen=True)
class Thread:
    id: str
    title: str
    rollout_path: str
    updated_at: int
    archived: bool
    title_source: str


def compact(text: str, limit: int = 100) -> str:
    value = " ".join((text or "").split())
    if not value:
        return "<без названия>"
    if len(value) <= limit:
        return value
    return value[: limit - 1] + "..."


def load_index() -> dict[str, dict[str, str]]:
    if not INDEX_PATH.exists():
        return {}

    result: dict[str, dict[str, str]] = {}
    for line_number, line in enumerate(INDEX_PATH.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Не удалось разобрать {INDEX_PATH}:{line_number}: {exc}") from exc
        thread_id = item.get("id")
        if thread_id:
            result[thread_id] = item
    return result


def load_db_threads() -> list[dict[str, object]]:
    if not STATE_DB_PATH.exists():
        return []

    con = sqlite3.connect(STATE_DB_PATH)
    con.row_factory = sqlite3.Row
    try:
        rows = con.execute(
            """
            select id, title, rollout_path, updated_at, archived
            from threads
            order by updated_at desc, id desc
            """
        ).fetchall()
    finally:
        con.close()
    return [dict(row) for row in rows]


def load_threads() -> list[Thread]:
    index = load_index()
    db_rows = load_db_threads()
    threads: list[Thread] = []
    seen: set[str] = set()

    for row in db_rows:
        thread_id = str(row["id"])
        title = str(row.get("title") or "")
        source = "sqlite"
        if thread_id in index and index[thread_id].get("thread_name"):
            title = str(index[thread_id]["thread_name"])
            source = "index"
        threads.append(
            Thread(
                id=thread_id,
                title=title,
                rollout_path=str(row.get("rollout_path") or ""),
                updated_at=int(row.get("updated_at") or 0),
                archived=bool(row.get("archived") or False),
                title_source=source,
            )
        )
        seen.add(thread_id)

    for item in index.values():
        thread_id = item["id"]
        if thread_id in seen:
            continue
        threads.append(
            Thread(
                id=thread_id,
                title=str(item.get("thread_name") or ""),
                rollout_path="",
                updated_at=0,
                archived=False,
                title_source="index-only",
            )
        )

    return threads


def backup_file(path: Path, stamp: str) -> Path | None:
    if not path.exists():
        return None
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    destination = BACKUP_DIR / f"{path.name}.{stamp}.bak"
    shutil.copy2(path, destination)
    return destination


def backup_sqlite(path: Path, stamp: str) -> Path | None:
    if not path.exists():
        return None
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    destination = BACKUP_DIR / f"{path.name}.{stamp}.bak"

    source = sqlite3.connect(path)
    target = sqlite3.connect(destination)
    try:
        source.backup(target)
    finally:
        target.close()
        source.close()
    return destination


def update_index(thread_id: str, new_title: str) -> bool:
    if not INDEX_PATH.exists():
        return False

    changed = False
    output: list[str] = []
    for line in INDEX_PATH.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        item = json.loads(line)
        if item.get("id") == thread_id:
            item["thread_name"] = new_title
            changed = True
        output.append(json.dumps(item, ensure_ascii=False, separators=(",", ":")))

    if changed:
        INDEX_PATH.write_text("\n".join(output) + "\n", encoding="utf-8")
    return changed


def update_sqlite(thread_id: str, new_title: str) -> bool:
    if not STATE_DB_PATH.exists():
        return False

    con = sqlite3.connect(STATE_DB_PATH)
    try:
        cur = con.execute("update threads set title = ? where id = ?", (new_title, thread_id))
        con.commit()
        return cur.rowcount > 0
    finally:
        con.close()


def rename_thread(thread: Thread, new_title: str) -> None:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    index_backup = backup_file(INDEX_PATH, stamp)
    sqlite_backup = backup_sqlite(STATE_DB_PATH, stamp)

    index_changed = update_index(thread.id, new_title)
    sqlite_changed = update_sqlite(thread.id, new_title)

    if not index_changed and not sqlite_changed:
        raise RuntimeError("Ни один источник названия не был обновлён. Изменения не применены.")

    print("\nГотово. Обновлено:")
    print(f"- session_index.jsonl: {'да' if index_changed else 'нет, записи с id не было'}")
    print(f"- state_5.sqlite: {'да' if sqlite_changed else 'нет, записи с id не было'}")
    print("Backup:")
    if index_backup:
        print(f"- {index_backup}")
    if sqlite_backup:
        print(f"- {sqlite_backup}")


def print_threads(threads: list[Thread]) -> None:
    if not threads:
        print("Диалоги не найдены.")
        return

    for number, thread in enumerate(threads, 1):
        archived = " архив" if thread.archived else ""
        print(
            f"{number:3}. {compact(thread.title)}"
            f"\n     id: {thread.id} | source: {thread.title_source}{archived}"
        )


def choose_thread(all_threads: list[Thread]) -> Thread | None:
    visible = all_threads

    while True:
        print("\nКоманды:")
        print("- номер: выбрать диалог")
        print("- /текст: отфильтровать по названию или id")
        print("- all: показать все")
        print("- q: выйти")
        print_threads(visible)

        value = input("\nВыбор: ").strip()
        if value.lower() in {"q", "quit", "exit"}:
            return None
        if value.lower() == "all":
            visible = all_threads
            continue
        if value.startswith("/"):
            query = value[1:].strip().lower()
            visible = [
                thread
                for thread in all_threads
                if query in thread.id.lower() or query in thread.title.lower()
            ]
            continue
        if value.isdigit():
            index = int(value) - 1
            if 0 <= index < len(visible):
                return visible[index]
            print("Нет такого номера в текущем списке.")
            continue
        print("Не понял команду.")


def confirm(prompt: str) -> bool:
    value = input(f"{prompt} [y/N]: ").strip().lower()
    return value in {"y", "yes", "д", "да"}


def main() -> int:
    print("Переименование локальных задач Codex")
    print(f"Codex home: {CODEX_HOME}")
    print("Совет: перед массовыми правками закрой VS Code/Codex, чтобы он не перезаписал индекс.\n")

    try:
        threads = load_threads()
    except Exception as exc:
        print(f"Ошибка чтения хранилища Codex: {exc}")
        return 1

    if not threads:
        print("Не нашёл диалоги в ~/.codex.")
        return 1

    thread = choose_thread(threads)
    if thread is None:
        print("Отменено.")
        return 0

    print("\nВыбран диалог:")
    print(f"id: {thread.id}")
    print(f"текущее название: {compact(thread.title, 300)}")
    if thread.rollout_path:
        print(f"файл диалога: {thread.rollout_path}")

    new_title = input("\nНовое название: ").strip()
    if not new_title:
        print("Пустое название не применяю.")
        return 1

    print("\nБудет изменено только название в индексе/базе. Файл диалога не удаляется и не переименовывается.")
    if not confirm("Применить переименование?"):
        print("Отменено.")
        return 0

    try:
        rename_thread(thread, new_title)
    except Exception as exc:
        print(f"Ошибка переименования: {exc}")
        print(f"Проверь backup в {BACKUP_DIR}, если часть изменений успела примениться.")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
