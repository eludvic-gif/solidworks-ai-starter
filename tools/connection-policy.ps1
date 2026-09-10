# Pure decisions: dot-sourcing this file never contacts CAD.
function Get-ConnectionDecision {
    param([int]$ProcessCount, [bool]$LaunchAllowed, [bool]$AlreadyLaunched)
    if ($ProcessCount -lt 0) { throw 'Invalid process count.' }
    if ($ProcessCount -gt 1) { throw 'Multiple SOLIDWORKS processes: ambiguous connection refused.' }
    if ($ProcessCount -eq 1) { return 'Probe' }
    if ($AlreadyLaunched) { throw 'SOLIDWORKS exited after launch. Crash loop prevented.' }
    if (-not $LaunchAllowed) { throw 'SOLIDWORKS absent. Open it manually or explicitly use -LaunchIfAbsent.' }
    return 'Launch'
}

function Get-ProbeDecision {
    param([bool]$TimedOut, [int]$ExitCode, [string]$ErrorText)
    if ($TimedOut) { return 'Timeout' }
    if ($ExitCode -eq 0) { return 'Connected' }
    if ($ErrorText -match '800401E3|MK_E_UNAVAILABLE|80010108|800706BA') { return 'Retry' }
    return 'Stop'
}

function Read-StarterConfig {
    param([string]$ConfigPath)
    if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion -lt [version]'5.1' -or -not [Environment]::Is64BitProcess) {
        throw 'Use 64-bit Windows PowerShell 5.1 (powershell.exe), not PowerShell 7 or x86.'
    }
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        throw 'Create config.local.json from config.example.json and verify the local paths.'
    }
    $config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($field in @('interop_path','executable_path')) {
        $value = [string]$config.$field
        if ($value -notmatch '^[A-Za-z]:\\' -or -not (Test-Path -LiteralPath $value -PathType Leaf)) {
            throw "Missing absolute local file for $field. Check configuration."
        }
    }
    if ([IO.Path]::GetFileName($config.interop_path) -ine 'SolidWorks.Interop.sldworks.dll') {
        throw 'Select the installed SolidWorks.Interop.sldworks.dll.'
    }
    if ([IO.Path]::GetFileName($config.executable_path) -ine 'SLDWORKS.exe') {
        throw 'Select the installed SLDWORKS.exe.'
    }
    if ([string]$config.expected_revision_prefix -notmatch '^\d+\.$') {
        throw 'An explicit major revision prefix such as 33. is required.'
    }
    return $config
}
