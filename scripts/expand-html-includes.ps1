param(
    [string]
    $Root
)

$pattern = "<!--\$\s*([a-zA-Z0-9-_]+\.[a-zA-Z0-9]+)\s*\$-->"
Write-Host "Processing includes for html files in: $Root"

Get-ChildItem -Path "$Root\src" -Filter "*.*" -Recurse |
Foreach-Object {
    if ($_.Extension -eq ".htm" -or $_.Extension -eq ".html") {
        $html = Get-Content $_.FullName
        $results = [Regex]::Matches($html, $pattern)
        $dirty = $false
        foreach($result in $results)
        {
            $includeFile = $result.Groups[1].value
            $includeFileFullPath = "$Root\includes\$includeFile"
            if (!(Test-Path $includeFileFullPath)) {
                throw "$includeFile not exist from includes."
            }

            $placeholder = $result.Groups[0].value
            $includeFileContent = Get-Content $includeFileFullPath
            $html = $html.Replace($placeholder, $includeFileContent)
            Write-Host "Expanded $includeFile in $_"
            $dirty = $true
        }

        if ($dirty) { 
            Set-Content -Path $_.FullName -Value $html
        }

        Write-Host "Processed $_"
    }
}

