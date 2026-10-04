$ErrorActionPreference = "Stop"

try {
    # Saubere Pfadbehandlung unabhaengig vom Aufrufort
    $outputFileName = "00_index.html"
    $templateFileName = "index_template.html"
    $outputPath = Join-Path -Path $PSScriptRoot -ChildPath $outputFileName
    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath $templateFileName
    $contentMarker = "<!-- CONTENT -->"
    $allowedExtensions = @(".html", ".htm", ".pdf")

    # Dateien sammeln, ohne Index- und Template-Datei. Versteckte und Systemdateien
    # laesst Get-ChildItem ohne -Force ohnehin aus; Namen mit "." am Anfang werden
    # zusaetzlich uebersprungen (wie im Python-Skript).
    $files = @(Get-ChildItem -LiteralPath $PSScriptRoot -File |
             Where-Object {
                 $allowedExtensions -contains $_.Extension.ToLower() -and
                 -not $_.Name.StartsWith(".") -and
                 $_.Name -ne $outputFileName -and
                 $_.Name -ne $templateFileName
             })

    # Natuerliche Sortierung: Zahlen werden auf 20 Stellen mit Nullen aufgefuellt,
    # damit "2" vor "10" steht (gilt fuer Zahlen mit bis zu 20 Stellen)
    $files = $files | Sort-Object -Property @{
        Expression = {
            $evaluator = [System.Text.RegularExpressions.MatchEvaluator] {
                param([System.Text.RegularExpressions.Match]$match)
                $match.Value.PadLeft(20, '0')
            }
            [System.Text.RegularExpressions.Regex]::Replace($_.Name, '\d+', $evaluator)
        }
    }

    # Gemeinsames HTML/CSS/JS-Template laden (wird auch vom Python-Skript genutzt)
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Template-Datei nicht gefunden: $templateFileName"
    }
    $template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
    $templateParts = $template -split [regex]::Escape($contentMarker), 2
    if ($templateParts.Count -ne 2) {
        throw "Template-Datei enthaelt keinen Platzhalter '$contentMarker'."
    }
    $htmlTop = $templateParts[0]
    $htmlBottom = $templateParts[1]

    # Encoding-Objekt erstellen, das explizit KEIN BOM (Byte-Order-Mark) schreibt ($false)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)

    if ($files.Count -eq 0) {
        $emptyHtml = $htmlTop + "<p>Keine Dateien gefunden.</p>" + $htmlBottom
        [System.IO.File]::WriteAllText($outputPath, $emptyHtml, $utf8NoBom)
        Write-Host "Leerer Index erstellt."
        exit
    }

    $groupedFiles = $files | Group-Object {
        $firstChar = $_.Name.Substring(0,1).ToLower()
        # Umlaute als Unicode-Escapes, damit die Zuordnung unabhaengig von der
        # Dateikodierung funktioniert (Windows PowerShell 5.1 liest Skripte ohne BOM als ANSI).
        # "break" verhindert, dass zusaetzlich der allgemeine Buchstaben-Zweig greift.
        switch -Regex ($firstChar) {
            "\u00E4" { "A"; break }
            "\u00F6" { "O"; break }
            "\u00FC" { "U"; break }
            "\u00DF" { "S"; break }
            "\p{L}" { $firstChar.ToUpper(); break }
            default { "#" }
        }
    } | Sort-Object Name

    $fileLabel = if ($files.Count -eq 1) { "1 Datei" } else { "$($files.Count) Dateien" }

    $htmlMiddle = "    <p id=`"fileCount`" class=`"file-count`">$fileLabel gefunden</p>`n"
    $htmlMiddle += "    <div class=`"search-container`">`n"
    $htmlMiddle += "        <label for=`"searchInput`" class=`"visually-hidden`">Dateien durchsuchen</label>`n"
    $htmlMiddle += "        <input type=`"search`" id=`"searchInput`" oninput=`"filterFiles()`" placeholder=`"Dateien durchsuchen ...`">`n"
    $htmlMiddle += "    </div>`n"

    $htmlMiddle += "    <div class=`"nav-alphabet`">`n"
    $groupNumber = 1
    foreach ($group in $groupedFiles) {
        $htmlMiddle += "        <a href=`"#group-$groupNumber`">$($group.Name)</a>`n"
        $groupNumber++
    }
    $htmlMiddle += "    </div>`n"

    $listItems = ""
    $groupNumber = 1
    foreach ($group in $groupedFiles) {
        $listItems += "    <section class=`"file-group`">`n"
        $listItems += "        <h2 id=`"group-$groupNumber`" class=`"letter-header`">$($group.Name)</h2>`n        <ul>`n"

        foreach ($file in $group.Group) {
            $ext = $file.Extension.ToLower()
            $typeTag = if ($ext -eq ".pdf") { "PDF" } else { "HTML" }

            $displayName = [System.Net.WebUtility]::HtmlEncode($file.Name)
            $fileUrl = [Uri]::EscapeDataString($file.Name)

            $listItems += "            <li><a class=`"file-link`" href=`"$fileUrl`"><span class=`"file-type-tag`">$typeTag</span><span class=`"file-name`">$displayName</span></a></li>`n"
        }

        $listItems += "        </ul>`n        <a href=`"#top`" class=`"back-to-top`">&#8593; Zur&uuml;ck nach oben</a>`n"
        $listItems += "    </section>`n"
        $groupNumber++
    }

    $finalHtml = $htmlTop + $htmlMiddle + $listItems + $htmlBottom

    # Datei schreiben ueber .NET-Klasse, um das BOM zu verhindern
    [System.IO.File]::WriteAllText($outputPath, $finalHtml, $utf8NoBom)

    Write-Host "Index erfolgreich aktualisiert: $outputFileName"

} catch {
    # Kein Write-Error: Wegen $ErrorActionPreference = "Stop" wuerde es hier selbst
    # einen neuen Abbruch ausloesen und "exit 1" nie erreicht werden.
    [Console]::Error.WriteLine("Der Index konnte nicht erstellt werden: $($_.Exception.Message)")
    exit 1
}
