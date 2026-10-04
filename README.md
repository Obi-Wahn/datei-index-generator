# Datei-Index-Generator

Erzeugt aus HTML-, HTM- und PDF-Dateien in einem Ordner eine durchsuchbare
`00_index.html` mit alphabetischer Gruppierung, natürlicher Sortierung
(z. B. `Kapitel 2` vor `Kapitel 10`) und Live-Suchfeld.

Es gibt zwei gleichwertige Implementierungen — Python und PowerShell —, die
beide dieselbe Vorlage (`index_template.html`) für Layout, Styles und die
Suchfunktion verwenden und dasselbe Ergebnis erzeugen.

## Funktionsweise

- Durchsucht **nur den Ordner, in dem sich das Skript befindet** (nicht
  rekursiv) nach Dateien mit den Endungen `.html`, `.htm` und `.pdf`.
  Versteckte Dateien (Windows-Attribut „versteckt“ bzw. „System“ oder Name
  mit `.` am Anfang) werden nicht aufgelistet.
- Sortiert die Dateien natürlich (Zahlen im Namen werden als Zahl, nicht als
  Zeichenkette verglichen) und wie im Wörterbuch: Groß-/Kleinschreibung,
  Umlaute und Akzente spielen für die Reihenfolge keine Rolle
  (`Apfel`, `Ärger`, `Azubi`).
- Gruppiert alphabetisch nach dem ersten Zeichen des Dateinamens:
  - Deutsche Umlaute werden dem Grundbuchstaben zugeordnet
    (ä → A, ö → O, ü → U, ß → S).
  - Andere Buchstaben mit Akzent bilden eine eigene Gruppe, die direkt
    hinter dem Grundbuchstaben steht (z. B. `É` hinter `E`).
  - Dateien, die nicht mit einem Buchstaben beginnen (z. B. `1_intro.pdf`),
    landen in der Gruppe **`#`** ganz am Anfang.
- Das Suchfeld filtert live nach dem **Dateinamen**. Groß-/Kleinschreibung,
  Umlaute und Akzente spielen dabei keine Rolle (`arger` findet `Ärger.html`).
- Schreibt das Ergebnis nach `00_index.html` im selben Ordner. Diese Datei
  wird bei jedem Lauf überschrieben und ist deshalb in `.gitignore`
  aufgeführt.

## Verwendung

### Voraussetzungen

- **Python-Variante:** Python 3.8 oder neuer (nur Standardbibliothek, keine
  zusätzlichen Pakete nötig).
- **PowerShell-Variante:** Windows PowerShell 5.1 (unter Windows 10/11
  vorinstalliert) oder PowerShell 7+. Die `.bat`-Datei startet immer
  Windows PowerShell 5.1 (`powershell.exe`).

### Ausführen

1. Folgende Dateien in den Ordner kopieren, der indiziert werden soll:
   - `index_template.html` (wird von beiden Varianten benötigt) **und**
   - für die Python-Variante: `00_index_erstellen.py` und
     `00_IndexErstellen - Python.bat`, **oder**
   - für die PowerShell-Variante: `00_IndexErstellen.ps1` und
     `00_IndexErstellen - PowerShell.bat`.
2. Die passende `.bat`-Datei per Doppelklick starten:
   - `00_IndexErstellen - Python.bat` → führt `00_index_erstellen.py` aus
     (verwendet den Python-Launcher `py`, falls vorhanden, sonst `python`).
   - `00_IndexErstellen - PowerShell.bat` → führt `00_IndexErstellen.ps1`
     aus.
3. Es entsteht `00_index.html` im selben Ordner. Diese Datei im Browser
   öffnen, um die durchsuchbare Übersicht zu sehen.

Wichtig:

- `00_index.html` verlinkt die Dateien **relativ**. Sie muss deshalb im
  selben Ordner wie die Dokumente bleiben; verschoben funktionieren die
  Links nicht mehr.
- Der Index wird nicht automatisch aktualisiert. Nach dem Hinzufügen,
  Umbenennen oder Löschen von Dateien das Skript erneut ausführen.

Alternativ lassen sich die Skripte auch direkt aus der Kommandozeile
starten:

```bash
# Windows (Python-Launcher)
py 00_index_erstellen.py

# Linux/macOS oder ohne Launcher
python3 00_index_erstellen.py
```

```powershell
powershell -ExecutionPolicy Bypass -File .\00_IndexErstellen.ps1
```

## Tests

Für die Python-Hilfsfunktionen (natürliche Sortierung, alphabetische
Gruppierung, Template-Ladefehler) gibt es Unit-Tests auf Basis der
Standardbibliothek `unittest`:

```bash
python -m unittest discover -s tests
```

## Dateien

| Datei | Zweck |
|---|---|
| `00_index_erstellen.py` | Python-Implementierung |
| `00_IndexErstellen.ps1` | PowerShell-Implementierung |
| `index_template.html` | Gemeinsames HTML/CSS/JS-Template beider Skripte |
| `00_IndexErstellen - Python.bat` | Windows-Starter für die Python-Variante |
| `00_IndexErstellen - PowerShell.bat` | Windows-Starter für die PowerShell-Variante |
| `tests/` | Unit-Tests für die Python-Variante |

## Lizenz

Siehe [LICENSE](LICENSE).
