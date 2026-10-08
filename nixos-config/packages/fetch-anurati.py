"""Получение бесплатной версии шрифта по постоянной ссылке автора."""

from html.parser import HTMLParser
from pathlib import Path
import subprocess
import sys
from urllib.parse import urlparse

PAGE = "https://www.mediafire.com/file/f68lm0c6fqg6njs/anurati_font-personal-use-only.zip/file"


def download(url):
    return subprocess.run(
        ["curl", "--fail", "--silent", "--show-error", "--location",
         "--retry", "2", "--max-time", "60", "--proto", "=https",
         "--proto-redir", "=https", "--user-agent", "Mozilla/5.0", url],
        check=True, capture_output=True,
    ).stdout


class DownloadLink(HTMLParser):
    url = None

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == "a" and values.get("id") == "downloadButton":
            self.url = values.get("href")


def main():
    parser = DownloadLink()
    parser.feed(download(PAGE).decode("utf-8"))
    parsed = urlparse(parser.url or "")
    if parsed.scheme != "https" or not (parsed.hostname or "").endswith(".mediafire.com"):
        raise RuntimeError("Ссылка на архив шрифта не найдена")
    Path(sys.argv[1]).write_bytes(download(parser.url))


if __name__ == "__main__":
    main()
