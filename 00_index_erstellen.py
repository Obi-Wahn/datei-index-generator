import sys
import re
from html import escape
from urllib.parse import quote
from pathlib import Path

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

# Globale Fehlerbehandlung für den gesamten Ablauf
try:
    SCRIPT_DIR = Path(__file__).resolve().parent
    OUTPUT_FILE = SCRIPT_DIR / "00_index.html"
    ALLOWED_EXTENSIONS = {".html", ".htm", ".pdf"}

    files = sorted(
        (
            path for path in SCRIPT_DIR.iterdir()
            if path.is_file()
            and path.name.casefold() != OUTPUT_FILE.name.casefold()
            and path.suffix.casefold() in ALLOWED_EXTENSIONS
        ),
        key=lambda path: natural_sort_key(path.name),
    )

    html_top = """<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Datei-&Uuml;bersicht</title>
    <style>
        html { scroll-behavior: smooth; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; color: #333; max-width: 800px; margin: 40px auto; padding: 0 20px; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .search-container { margin-bottom: 30px; margin-top: 20px; }
        .visually-hidden { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }
        #searchInput { width: 100%; padding: 15px 20px; font-size: 16px; border: 2px solid #ddd; border-radius: 8px; box-sizing: border-box; transition: border-color 0.3s; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
        #searchInput:focus { border-color: #3498db; outline: none; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .file-count { color: #7f8c8d; font-size: 0.9em; margin-bottom: 20px; }
        .nav-alphabet { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 30px; background: #ffffff; padding: 15px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
        .nav-alphabet a { display: inline-block; padding: 8px 14px; background-color: #e9ecef; color: #2c3e50; text-decoration: none; border-radius: 6px; font-weight: bold; transition: all 0.2s; }
        .nav-alphabet a:hover { background-color: #3498db; color: #ffffff; transform: translateY(-2px); }
        h2.letter-header { color: #3498db; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; }
        ul { list-style-type: none; padding: 0; }
        li { margin: 12px 0; }
        .file-link { display: block; text-decoration: none; color: #2c3e50; background-color: #ffffff; padding: 15px 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.05); border-left: 5px solid #3498db; transition: all 0.2s ease-in-out; }
        .file-link:hover { background-color: #3498db; color: #ffffff; transform: translateX(8px); box-shadow: 0 4px 10px rgba(0,0,0,0.15); }
        .file-type-tag { display: inline-block; background: #e2e8f0; color: #334155; font-size: 0.75em; padding: 2px 6px; border-radius: 4px; margin-right: 8px; font-weight: bold; vertical-align: middle; }
        .file-name { font-weight: bold; }
        .back-to-top { display: inline-block; margin-top: 10px; font-size: 0.9em; color: #7f8c8d; text-decoration: none; }
        .back-to-top:hover { color: #3498db; text-decoration: underline; }
    </style>
</head>
<body id="top">
    <h1>Meine Dokumente</h1>
"""

    html_bottom = """
    <script>
    function filterFiles() {
        const input = document.getElementById("searchInput");
        const filter = input.value.toLocaleLowerCase("de");
        let totalVisible = 0;

        document.querySelectorAll(".file-group").forEach(group => {
            let visibleCount = 0;

            group.querySelectorAll("li").forEach(item => {
                const matches = item.textContent.toLocaleLowerCase("de").includes(filter);
                item.hidden = !matches;
                if (matches) {
                    visibleCount++;
                    totalVisible++;
                }
            });

            group.hidden = visibleCount === 0;

            const groupId = group.querySelector("h2").id;
            const navLink = document.querySelector(`.nav-alphabet a[href="#${groupId}"]`);
            if (navLink) {
                navLink.style.display = visibleCount === 0 ? "none" : "inline-block";
            }
        });

        const countDisplay = document.getElementById("fileCount");
        if (countDisplay) {
            countDisplay.textContent = totalVisible === 1 ? "1 Datei gefunden" : `${totalVisible} Dateien gefunden`;
        }
    }
    </script>
</body>
</html>
"""

    if not files:
        final_html = html_top + "<p>Keine Dateien gefunden.</p>" + html_bottom
        OUTPUT_FILE.write_text(final_html, encoding="utf-8")
        print("Leerer Index erstellt.")
        sys.exit(0)

    grouped_files = {}
    for path in files:
        letter = get_group_letter(path.name)
        if letter not in grouped_files:
            grouped_files[letter] = []
        grouped_files[letter].append(path)

    sorted_letters = sorted(grouped_files.keys())

    file_label = "Datei" if len(files) == 1 else "Dateien"
    html_middle = f'    <p id="fileCount" class="file-count">{len(files)} {file_label} gefunden</p>\n'
    html_middle += '    <div class="search-container">\n'
    html_middle += '        <label for="searchInput" class="visually-hidden">Dateien durchsuchen</label>\n'
    html_middle += '        <input type="search" id="searchInput" oninput="filterFiles()" placeholder="Dateien durchsuchen ...">\n'
    html_middle += '    </div>\n'

    html_middle += '    <div class="nav-alphabet">\n'
    for group_number, letter in enumerate(sorted_letters, start=1):
        html_middle += f'        <a href="#group-{group_number}">{letter}</a>\n'
    html_middle += '    </div>\n'

    list_items = ""
    for group_number, letter in enumerate(sorted_letters, start=1):
        list_items += f'<section class="file-group">\n'
        list_items += f'    <h2 id="group-{group_number}" class="letter-header">{letter}</h2>\n    <ul>\n'

        for path in grouped_files[letter]:
            ext = path.suffix.casefold()
            type_tag = "PDF" if ext == ".pdf" else "HTML"
            display_name = escape(path.name)
            file_url = quote(path.name, safe="")

            list_items += (
                f'        <li><a class="file-link" href="{file_url}">'
                f'<span class="file-type-tag">{type_tag}</span>'
                f'<span class="file-name">{display_name}</span>'
                f'</a></li>\n'
            )
        list_items += '    </ul>\n    <a href="#top" class="back-to-top">&#8593; Zur&uuml;ck nach oben</a>\n'
        list_items += '</section>\n'

    final_html = html_top + html_middle + list_items + html_bottom
    OUTPUT_FILE.write_text(final_html, encoding="utf-8")

    print(f"Index erfolgreich aktualisiert: {OUTPUT_FILE.name}")

except Exception as error:
    print(f"Beim Erstellen des Index ist ein Fehler aufgetreten: {error}", file=sys.stderr)
    sys.exit(1)
