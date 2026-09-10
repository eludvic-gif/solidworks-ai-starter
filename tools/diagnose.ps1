param([string]$ConfigPath = (Join-Path $PSScriptRoot '..\config.local.json'))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'connection-policy.ps1')
$config = Read-StarterConfig $ConfigPath
[void][Reflection.Assembly]::LoadFrom($config.interop_path)
Add-Type -Path (Join-Path $PSScriptRoot 'SwConnection.cs') -ReferencedAssemblies $config.interop_path
Write-Output ('Interop assembly: ' + [SolidWorks.Interop.sldworks.ISldWorks].Assembly.GetName().Version)
Write-Output ('Configured application prefix: ' + $config.expected_revision_prefix)
foreach ($name in @('FeatureRevolve2','FeatureExtrusion3')) {
    $method = [SolidWorks.Interop.sldworks.IFeatureManager].GetMethod($name)
    if ($null -eq $method) { throw "Method not found: $name" }
    Write-Output ($name + ' parameters=' + $method.GetParameters().Count)
    $method.GetParameters() | ForEach-Object { Write-Output ('  ' + $_.Position + ': ' + $_.ParameterType.Name + ' ' + $_.Name) }
}
Write-Output 'OFFLINE DIAGNOSIS OK: paths checked and C# compiled; no COM attach, launch or document operation.'
