$ErrorActionPreference = "Stop"

$sourceRoot = Join-Path $PSScriptRoot "..\.sources"
New-Item -ItemType Directory -Force -Path $sourceRoot | Out-Null

$repositories = @(
    @{ Name = "data-science-interviews"; Url = "https://github.com/alexeygrigorev/data-science-interviews.git" },
    @{ Name = "Machine-Learning-Interviews"; Url = "https://github.com/alirezadir/Machine-Learning-Interviews.git" },
    @{ Name = "ai-engineering-interview-questions"; Url = "https://github.com/amitshekhariitbhu/ai-engineering-interview-questions.git" },
    @{ Name = "system-design-primer"; Url = "https://github.com/donnemartin/system-design-primer.git" }
)

foreach ($repository in $repositories) {
    $target = Join-Path $sourceRoot $repository.Name

    if (Test-Path $target) {
        Write-Host "[SKIP] $($repository.Name) already exists."
        continue
    }

    Write-Host "[CLONE] $($repository.Name)"
    git clone --depth 1 $repository.Url $target
}

Write-Host "Source repositories are ready in .sources."
