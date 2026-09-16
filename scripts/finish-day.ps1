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

# Backend track is paused: 0 or 1 Backend notes are both acceptable.
if ($backendNotes.Count -gt 1) {
    throw "At most one Backend note is allowed for $Date. Found: $($backendNotes.Count)"
}

function Assert-CompletedNote {
    param([System.IO.FileInfo]$Note)

    $content = Get-Content -Raw -Encoding UTF8 $Note.FullName

    if ($content -notmatch "(?m)^status:\s*completed\s*$") {
        throw "Note is not completed: $($Note.FullName)"
    }
}

Assert-CompletedNote $aiDataNotes[0]
if ($backendNotes.Count -eq 1) {
    Assert-CompletedNote $backendNotes[0]
}

# Resolve a real interpreter: the bare `python` on PATH can be the
# Microsoft Store stub, which prints "Python" and exits 0 without running.
$python = $null
foreach ($candidate in @(
    (Join-Path $root ".venv\Scripts\python.exe"),
    (Join-Path $root "venv\Scripts\python.exe")
)) {
    if (Test-Path $candidate) { $python = $candidate; break }
}
if (-not $python) {
    if (Get-Command py -ErrorAction SilentlyContinue) { $python = "py" }
    elseif (Get-Command python -ErrorAction SilentlyContinue) { $python = "python" }
    else { throw "No Python interpreter found." }
}

& $python .\scripts\update_dashboard.py
if ($LASTEXITCODE -ne 0) {
    throw "Dashboard update failed."
}

$notePaths = @($aiDataNotes[0].FullName)
if ($backendNotes.Count -eq 1) {
    $notePaths += $backendNotes[0].FullName
}

git add -- README.md CURRICULUM.md AGENTS.md @notePaths

$changes = git diff --cached --name-only
if (-not $changes) {
    throw "There are no staged changes to commit."
}

$tracks = if ($backendNotes.Count -eq 1) { "AI-DA and Backend" } else { "AI-DA" }
$commitMessage = "study: $Date $tracks"
git commit -m $commitMessage

if (-not $NoPush) {
    git push
}

Write-Host "Daily study completed."
Write-Host "Commit: $commitMessage"
