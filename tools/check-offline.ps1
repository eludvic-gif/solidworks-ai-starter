param([string]$ConfigPath)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1') {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ($file.Name + ': ' + ($errors -join '; ')) }
}
. (Join-Path $PSScriptRoot 'connection-policy.ps1')
function Assert-Equal($Actual, $Expected) {
    if ($Actual -ne $Expected) { throw "Expected $Expected, got $Actual" }
}
function Assert-Throws([scriptblock]$Action) {
    $threw = $false
    try { & $Action | Out-Null } catch { $threw = $true }
    if (-not $threw) { throw 'Expected refusal.' }
}
Assert-Throws { Get-ConnectionDecision 0 $false $false }
Assert-Throws { Get-ConnectionDecision 0 $true $true }
Assert-Throws { Get-ConnectionDecision 2 $true $false }
Assert-Equal (Get-ConnectionDecision 0 $true $false) 'Launch'
Assert-Equal (Get-ConnectionDecision 1 $false $false) 'Probe'
Assert-Equal (Get-ProbeDecision $true 0 '') 'Timeout'
Assert-Equal (Get-ProbeDecision $false 0 '') 'Connected'
Assert-Equal (Get-ProbeDecision $false 2 '800401E3 MK_E_UNAVAILABLE') 'Retry'
Assert-Equal (Get-ProbeDecision $false 2 '80010108') 'Retry'
Assert-Equal (Get-ProbeDecision $false 2 '800706BA') 'Retry'
Assert-Equal (Get-ProbeDecision $false 2 'wrong version') 'Stop'
Write-Output 'PowerShell parse + 11 policy checks PASS (pure functions only).'
if ($ConfigPath) {
    & (Join-Path $PSHOME 'powershell.exe') -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'diagnose.ps1') -ConfigPath $ConfigPath
    if ($LASTEXITCODE -ne 0) { throw 'Offline compilation failed.' }
} else { Write-Output 'C# compilation SKIPPED: provide -ConfigPath for installed interop.' }
Write-Output 'No SOLIDWORKS attach/launch/edit/close performed; timeout process handling is not integration-tested.'
