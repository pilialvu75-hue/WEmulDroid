$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'src' 'Updates.ps1')

$cases = @(
    @('v0.8.0-beta.1','v0.7.0',1),
    @('v0.8.0-beta.1','v0.8.0-beta.1',0),
    @('v0.8.0-beta.2','v0.8.0-beta.1',1),
    @('v0.8.0-rc.1','v0.8.0-beta.8',1),
    @('v0.8.0','v0.8.0-rc.1',1),
    @('v0.8.0','v0.8.0',0),
    @('v0.8.0-beta.1','v0.8.0',-1),
    @('v1.0.0','v0.99.99',1),
    @('v0.7.0','v0.8.0-beta.1',-1)
)
foreach ($test in $cases) {
    $actual = Compare-WEmulDroidVersion $test[0] $test[1]
    if ($actual -ne $test[2]) {
        throw "Unexpected version ordering: $($test[0]) vs $($test[1]): $actual"
    }
}
foreach ($bad in @('http://bad','v1.2','v1.2.3-test','v1.2.3/../../')) {
    $rejected = $false
    try { [void](Compare-WEmulDroidVersion $bad 'v0.0.0') } catch { $rejected=$true }
    if (-not $rejected) { throw "Invalid version accepted: $bad" }
}
Write-Host 'PASS: WEmulDroid official update version sorting and input validation'
