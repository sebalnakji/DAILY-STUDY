param(
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

$year = $Date.Substring(0, 4)
$notesDirectory = Join-Path $root "notes\$year"

if (-not (Test-Path $notesDirectory)) {
    throw "Notes directory not found: $notesDirectory"
}

$aiDataNotes = @(Get-ChildItem -Path $notesDirectory -Filter "$Date-ai-data-*.md")
$backendNotes = @(Get-ChildItem -Path $notesDirectory -Filter "$Date-backend-*.md")

if ($aiDataNotes.Count -ne 1) {
    throw "Exactly one AI·Data note is required for $Date. Found: $($aiDataNotes.Count)"
}

if ($backendNotes.Count -ne 1) {
    throw "Exactly one Backend note is required for $Date. Found: $($backendNotes.Count)"
}

function Assert-CompletedNote {
    param([System.IO.FileInfo]$Note)

    $content = Get-Content -Raw -Encoding UTF8 $Note.FullName

    if ($content -notmatch "(?m)^status:\s*completed\s*$") {
        throw "Note is not completed: $($Note.FullName)"
    }
}

Assert-CompletedNote $aiDataNotes[0]
Assert-CompletedNote $backendNotes[0]

python .\scripts\update_dashboard.py
if ($LASTEXITCODE -ne 0) {
    throw "Dashboard update failed."
}

git add -- README.md CURRICULUM.md $aiDataNotes[0].FullName $backendNotes[0].FullName

$changes = git diff --cached --name-only
if (-not $changes) {
    throw "There are no staged changes to commit."
}

$commitMessage = "study: $Date AI·Data and Backend"
git commit -m $commitMessage

if (-not $NoPush) {
    git push
}

Write-Host "Daily study completed."
Write-Host "Commit: $commitMessage"
