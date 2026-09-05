import sys
import re
from html import escape
from urllib.parse import quote
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_FILE = SCRIPT_DIR / "00_index.html"
TEMPLATE_FILE = SCRIPT_DIR / "index_template.html"
CONTENT_MARKER = "<!-- CONTENT -->"
ALLOWED_EXTENSIONS = {".html", ".htm", ".pdf"}


def natural_sort_key(filename: str) -> list:
    return [
        int(part) if part.isdigit() else part.casefold()
        for part in re.split(r"(\d+)", filename)
    ]


def get_group_letter(filename: str) -> str:
    first_character = filename[0]
    german_mapping = {"ä": "A", "ö": "O", "ü": "U", "ß": "S"}

    if not first_character.isalpha():
        return "#"

    return german_mapping.get(first_character.lower(), first_character.upper())


def collect_files() -> list:
    excluded_names = {OUTPUT_FILE.name.casefold(), TEMPLATE_FILE.name.casefold()}
    return sorted(
        (
            path for path in SCRIPT_DIR.iterdir()
            if path.is_file()
            and path.name.casefold() not in excluded_names
            and path.suffix.casefold() in ALLOWED_EXTENSIONS
        ),
        key=lambda path: natural_sort_key(path.name),
    )


def load_template() -> tuple:
    if not TEMPLATE_FILE.is_file():
        raise FileNotFoundError(f"Template-Datei nicht gefunden: {TEMPLATE_FILE.name}")

    template = TEMPLATE_FILE.read_text(encoding="utf-8")
    if CONTENT_MARKER not in template:
        raise ValueError(f"Template-Datei enthaelt keinen Platzhalter '{CONTENT_MARKER}'.")

    html_top, html_bottom = template.split(CONTENT_MARKER, 1)
    return html_top, html_bottom


def render_file_list(files: list) -> str:
    grouped_files = {}
    for path in files:
        letter = get_group_letter(path.name)
        grouped_files.setdefault(letter, []).append(path)

    sorted_letters = sorted(grouped_files.keys())

    file_label = "Datei" if len(files) == 1 else "Dateien"
    content = f'    <p id="fileCount" class="file-count">{len(files)} {file_label} gefunden</p>\n'
    content += '    <div class="search-container">\n'
    content += '        <label for="searchInput" class="visually-hidden">Dateien durchsuchen</label>\n'
    content += '        <input type="search" id="searchInput" oninput="filterFiles()" placeholder="Dateien durchsuchen ...">\n'
    content += '    </div>\n'

    content += '    <div class="nav-alphabet">\n'
    for group_number, letter in enumerate(sorted_letters, start=1):
        content += f'        <a href="#group-{group_number}">{letter}</a>\n'
    content += '    </div>\n'

    for group_number, letter in enumerate(sorted_letters, start=1):
        content += f'<section class="file-group">\n'
        content += f'    <h2 id="group-{group_number}" class="letter-header">{letter}</h2>\n    <ul>\n'

        for path in grouped_files[letter]:
            ext = path.suffix.casefold()
            type_tag = "PDF" if ext == ".pdf" else "HTML"
            display_name = escape(path.name)
            file_url = quote(path.name, safe="")

            content += (
                f'        <li><a class="file-link" href="{file_url}">'
                f'<span class="file-type-tag">{type_tag}</span>'
                f'<span class="file-name">{display_name}</span>'
                f'</a></li>\n'
            )
        content += '    </ul>\n    <a href="#top" class="back-to-top">&#8593; Zur&uuml;ck nach oben</a>\n'
        content += '</section>\n'

    return content


def main() -> None:
    files = collect_files()
    html_top, html_bottom = load_template()

    if not files:
        final_html = html_top + "<p>Keine Dateien gefunden.</p>" + html_bottom
        OUTPUT_FILE.write_text(final_html, encoding="utf-8")
        print("Leerer Index erstellt.")
        return

    final_html = html_top + render_file_list(files) + html_bottom
    OUTPUT_FILE.write_text(final_html, encoding="utf-8")
    print(f"Index erfolgreich aktualisiert: {OUTPUT_FILE.name}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Beim Erstellen des Index ist ein Fehler aufgetreten: {error}", file=sys.stderr)
        sys.exit(1)
