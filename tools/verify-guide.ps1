# Optional convenience: run all offline checks from any working directory.
param([string]$ConfigPath)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if ($ConfigPath) { $ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path }
Push-Location $root
try {
    & python -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { throw 'Python tests failed.' }
    & python tools/scan_release.py
    if ($LASTEXITCODE -ne 0) { throw 'Release scan failed.' }
    $arguments = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $PSScriptRoot 'check-offline.ps1'))
    if ($ConfigPath) { $arguments += @('-ConfigPath', $ConfigPath) }
    & (Join-Path $PSHOME 'powershell.exe') @arguments
    if ($LASTEXITCODE -ne 0) { throw 'PowerShell/C# checks failed.' }
} finally { Pop-Location }
