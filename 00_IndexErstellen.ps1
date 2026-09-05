$ErrorActionPreference = "Stop"

try {
    # Saubere Pfadbehandlung unabhängig vom Aufrufort
    $outputFileName = "00_index.html"
    $outputPath = Join-Path -Path $PSScriptRoot -ChildPath $outputFileName
    $allowedExtensions = @(".html", ".htm", ".pdf")

    # Dateien sicher sammeln (inklusive Verstecken der Index-Datei)
    $files = @(Get-ChildItem -LiteralPath $PSScriptRoot -File |
             Where-Object {
                 $allowedExtensions -contains $_.Extension.ToLower() -and
                 $_.Name -ne $outputFileName
             })

    # Natürliche Sortierung für PowerShell (Padding auf 20 Stellen erhöht für absolute Sicherheit)
    $files = $files | Sort-Object -Property @{
        Expression = {
            $evaluator = [System.Text.RegularExpressions.MatchEvaluator] {
                param([System.Text.RegularExpressions.Match]$match)
                $match.Value.PadLeft(20, '0')
            }
            [System.Text.RegularExpressions.Regex]::Replace($_.Name, '\d+', $evaluator)
        }
    }

    # HTML Header & CSS
    $htmlTop = @"
<!DOCTYPE html>
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
"@

    $htmlBottom = @"
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
            const navLink = document.querySelector('.nav-alphabet a[href="#' + groupId + '"]');
            if (navLink) {
                navLink.style.display = visibleCount === 0 ? "none" : "inline-block";
            }
        });

        const countDisplay = document.getElementById("fileCount");
        if (countDisplay) {
            countDisplay.textContent = totalVisible === 1 ? "1 Datei gefunden" : totalVisible + " Dateien gefunden";
        }
    }
    </script>
</body>
</html>
"@

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
        switch -Regex ($firstChar) {
            "ä" { "A" }
            "ö" { "O" }
            "ü" { "U" }
            "ß" { "S" }
            "\p{L}" { $firstChar.ToUpper() }
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

    # Datei schreiben über .NET-Klasse, um das BOM zu verhindern
    [System.IO.File]::WriteAllText($outputPath, $finalHtml, $utf8NoBom)

    Write-Host "Index erfolgreich aktualisiert: $outputFileName"

} catch {
    Write-Error "Der Index konnte nicht erstellt werden: $($_.Exception.Message)"
    exit 1
}
