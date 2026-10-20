<#
.SYNOPSIS
  Ejecuta un comando de Flutter inyectando las variables de `.env` como
  `--dart-define`, para que ninguna clave viva en el codigo fuente.

.DESCRIPTION
  Lee `.env` (KEY=VALUE, ignora lineas vacias y comentarios `#`) y traduce
  cada entrada a `--dart-define=KEY=VALUE`. El archivo `.env` esta en
  `.gitignore`, por lo que nunca se sube al repositorio; en el repo solo
  existe `.env.example` con valores vacios.

.EXAMPLE
  .\scripts\flutter-env.ps1 build apk -Mode release
  .\scripts\flutter-env.ps1 build apk -Mode debug -SplitAbi
  .\scripts\flutter-env.ps1 run -Mode debug
  .\scripts\flutter-env.ps1 analyze
#>
param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet('build', 'run', 'analyze', 'test')]
  [string]$Task,

  [Parameter(Position = 1)]
  [string]$Target,   # ej. apk, appbundle

  [ValidateSet('release', 'debug', 'profile')]
  [string]$Mode = 'release',

  [switch]$SplitAbi,
  [switch]$NoEnv     # ignora .env (por si quieres una build sin claves)
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$defines = @()
$envFile = Join-Path $root '.env'

if (-not $NoEnv -and (Test-Path -LiteralPath $envFile)) {
  foreach ($raw in Get-Content -LiteralPath $envFile) {
    $line = $raw.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
    $i = $line.IndexOf('=')
    if ($i -le 0) { continue }
    $key = $line.Substring(0, $i).Trim()
    $value = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
    if ([string]::IsNullOrWhiteSpace($value)) { continue }   # no pasamos claves vacias
    $defines += "--dart-define=$key=$value"
    Write-Host ("  inyectada: {0} = {1}" -f $key, ($value.Substring(0, [Math]::Min(6, $value.Length)) + '***')) -ForegroundColor DarkGray
  }
}

$args_ = @()
switch ($Task) {
  'build' {
    $args_ = @('build')
    if ($Target) { $args_ += $Target } else { $args_ += 'apk' }
    $args_ += "--$Mode"
    if ($SplitAbi) { $args_ += '--split-per-abi' }
  }
  'run'     { $args_ = @('run'); if ($Target) { $args_ += $Target }; $args_ += "--$Mode" }
  'analyze' { $args_ = @('analyze') }
  'test'    { $args_ = @('test') }
}

# Solo `build` y `run` aceptan --dart-define (analyze/test lo rechazan).
if ($Task -eq 'build' -or $Task -eq 'run') { $args_ += $defines }

Write-Host "flutter $($args_ -join ' ')" -ForegroundColor Cyan
& flutter @args_
exit $LASTEXITCODE
