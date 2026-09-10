param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config.local.json'),
    [switch]$LaunchIfAbsent,
    [ValidateRange(1,20)][int]$Attempts = 8,
    [switch]$ProbeChild
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'connection-policy.ps1')
$config = Read-StarterConfig $ConfigPath
$ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
if ($ProbeChild) {
    try {
        [void][Reflection.Assembly]::LoadFrom($config.interop_path)
        Add-Type -Path (Join-Path $PSScriptRoot 'SwConnection.cs') -ReferencedAssemblies $config.interop_path
        [StarterConnection]::Probe($config.expected_revision_prefix)
        exit 0
    } catch { [Console]::Error.WriteLine($_.Exception.ToString()); exit 2 }
}
$launched = $false
for ($i = 1; $i -le $Attempts; $i++) {
    $cad = @(Get-Process SLDWORKS -ErrorAction SilentlyContinue)
    $decision = Get-ConnectionDecision $cad.Count ([bool]$LaunchIfAbsent) $launched
    if ($decision -eq 'Launch') {
        Start-Process -FilePath $config.executable_path | Out-Null
        $launched = $true
        Write-Output 'Started SOLIDWORKS. Waiting for registration; no document operation will be replayed.'
    }
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = Join-Path $PSHOME 'powershell.exe'
    $info.Arguments = '-NoProfile -NonInteractive -File "' + $PSCommandPath + '" -ProbeChild -ConfigPath "' + $ConfigPath + '"'
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $client = New-Object Diagnostics.Process
    $client.StartInfo = $info
    try {
        [void]$client.Start()
        $stdout = $client.StandardOutput.ReadToEndAsync()
        $stderr = $client.StandardError.ReadToEndAsync()
        $timedOut = -not $client.WaitForExit(12000)
        if ($timedOut) {
            # Kill only this disposable PowerShell client, never the CAD process.
            $client.Kill()
            [void]$client.WaitForExit(3000)
            throw 'COM probe timed out. SOLIDWORKS and unsaved documents were NOT closed.'
        }
        $code = $client.ExitCode
        $out = $stdout.Result
        $err = $stderr.Result
    } finally { $client.Dispose() }
    $probeDecision = Get-ProbeDecision $false $code $err
    if ($probeDecision -eq 'Connected') {
        # Recheck count and returned PID to reject a process race/ambiguous ROT entry.
        $current = @(Get-Process SLDWORKS -ErrorAction SilentlyContinue)
        if ($out -notmatch 'pid=(\d+)') { throw 'Probe returned no process identity.' }
        $probePid = [int]$Matches[1]
        if ($current.Count -ne 1 -or $current[0].Id -ne $probePid) {
            throw 'Process identity changed during probe. Stopping without CAD operations.'
        }
        Write-Output $out.Trim()
        exit 0
    }
    if ($probeDecision -ne 'Retry') { throw ('Non-transient probe failure: ' + $err) }
    Write-Output "COM unavailable; attempt $i/$Attempts."
    if ($i -lt $Attempts) { Start-Sleep -Seconds 3 }
}
throw 'Connection unavailable after bounded attempts. Existing CAD process and documents left untouched.'
