param([string]$GodotPath = "godot", [string]$PythonPath = "python")
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $projectRoot
try {
    New-Item -ItemType Directory -Force -Path "build/web" | Out-Null
    New-Item -ItemType File -Force -Path "build/.gdignore" | Out-Null
    if (-not (Test-Path -LiteralPath ".runtime/templates/web_nothreads_release.zip")) {
        & $PythonPath tools/fetch_web_template.py
        if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar o template web oficial." }
    }
    & $GodotPath --headless --path . --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw "Falha na importação do projeto." }
    & $GodotPath --headless --path . --export-release Web build/web/index.html
    if ($LASTEXITCODE -ne 0) { throw "Falha na exportação web." }
    $webFiles = Get-ChildItem -LiteralPath "build/web" -File | Where-Object { $_.Extension -ne ".import" }
    Compress-Archive -LiteralPath $webFiles.FullName -DestinationPath "build/astro-web.zip" -Force
    Write-Output "Jogo exportado: build/web/index.html"
    Write-Output "Pacote para hospedagem: build/astro-web.zip"
} finally { Pop-Location }
