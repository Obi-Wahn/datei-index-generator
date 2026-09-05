# Datei-Index-Generator

Erzeugt aus HTML-, HTM- und PDF-Dateien in einem Ordner eine durchsuchbare
`00_index.html` mit alphabetischer Gruppierung, natürlicher Sortierung
(z. B. `Kapitel 2` vor `Kapitel 10`) und Live-Suchfeld.

Es gibt zwei gleichwertige Implementierungen — Python und PowerShell —, die
beide dieselbe Vorlage (`index_template.html`) für Layout, Styles und die
Suchfunktion verwenden.

## Funktionsweise

- Durchsucht **nur den Ordner, in dem sich das Skript befindet** (nicht
  rekursiv) nach Dateien mit den Endungen `.html`, `.htm` und `.pdf`.
- Sortiert die Dateien natürlich (Zahlen im Namen werden als Zahl, nicht als
  Zeichenkette verglichen) und gruppiert sie alphabetisch, wobei deutsche
  Umlaute mit einsortiert werden (ä → A, ö → O, ü → U, ß → S).
- Schreibt das Ergebnis nach `00_index.html` im selben Ordner. Diese Datei
  wird bei jedem Lauf überschrieben und ist deshalb in `.gitignore`
  aufgeführt.

## Verwendung

### Voraussetzungen

- **Python-Variante:** Python 3.8 oder neuer (nur Standardbibliothek, keine
  zusätzlichen Pakete nötig).
- **PowerShell-Variante:** Windows PowerShell oder PowerShell 7+.

### Ausführen

1. Alle Skripte (`00_index_erstellen.py` bzw. `00_IndexErstellen.ps1`),
   die zugehörige `.bat`-Datei und `index_template.html` in den Ordner legen,
   der indiziert werden soll.
2. Je nach gewünschter Variante eine der folgenden Dateien starten
   (Doppelklick unter Windows genügt):
   - `00_IndexErstellen - Python.bat` → führt `00_index_erstellen.py` aus
     (sucht automatisch nach `py` bzw. `python` im PATH).
   - `00_IndexErstellen - PowerShell.bat` → führt `00_IndexErstellen.ps1`
     aus.
3. Es entsteht `00_index.html` im selben Ordner. Diese Datei im Browser
   öffnen, um die durchsuchbare Übersicht zu sehen.

Alternativ lassen sich die Skripte auch direkt aus der Kommandozeile
starten:

```bash
python 00_index_erstellen.py
```

```powershell
powershell -ExecutionPolicy Bypass -File .\00_IndexErstellen.ps1
```

## Dateien

| Datei | Zweck |
|---|---|
| `00_index_erstellen.py` | Python-Implementierung |
| `00_IndexErstellen.ps1` | PowerShell-Implementierung |
| `index_template.html` | Gemeinsames HTML/CSS/JS-Template beider Skripte |
| `00_IndexErstellen - Python.bat` | Windows-Starter für die Python-Variante |
| `00_IndexErstellen - PowerShell.bat` | Windows-Starter für die PowerShell-Variante |

## Lizenz

Siehe [LICENSE](LICENSE).
