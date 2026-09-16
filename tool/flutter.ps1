$ErrorActionPreference = 'Stop'
$localSdk = Join-Path $PSScriptRoot '../work/flutter/bin/flutter.bat'
if ($env:FLUTTER_ROOT) {
    $flutterCommand = Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat'
} elseif (Test-Path -LiteralPath $localSdk) {
    $flutterCommand = $localSdk
} else {
    $flutterCommand = (Get-Command flutter -ErrorAction Stop).Source
}
& $flutterCommand @args
exit $LASTEXITCODE
