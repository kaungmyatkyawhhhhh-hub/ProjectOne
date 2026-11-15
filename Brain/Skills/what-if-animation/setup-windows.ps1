# What If animation: one-click setup for Windows. Checks each tool, installs only what is missing, logs to setup-log.txt.
$ErrorActionPreference = 'Continue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'setup-log.txt') -Force | Out-Null
function Refresh { $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User') }
function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Winget($id) { Write-Host "Installing $id ..."; winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent; Refresh }

Write-Host "`n== Node.js 18+ =="
$nodeOk = $false
if (Have node) { $v = (node -v) -replace 'v',''; Write-Host "found node $v"; $nodeOk = ([int]($v.Split('.')[0]) -ge 18) }
if (-not $nodeOk) { Winget 'OpenJS.NodeJS.LTS' }

Write-Host "`n== ffmpeg + ffprobe =="
if ((Have ffmpeg) -and (Have ffprobe)) { Write-Host 'found ffmpeg' } else { Winget 'Gyan.FFmpeg' }

Write-Host "`n== Python 3.9+ =="
$py = $null
foreach ($c in @('python','py')) {
  if (Have $c) { $out = & $c -c "import sys;print(sys.version_info>=(3,9))" 2>$null; if ($out -eq 'True') { $py = $c; break } }
}
if (-not $py) { Winget 'Python.Python.3.12'; $py = 'python' }
Write-Host "using $py :" (& $py --version)

Write-Host "`n== Python packages (numpy, Pillow, piper-tts, faster-whisper) =="
& $py -m pip install --upgrade pip
& $py -m pip install --upgrade numpy pillow piper-tts faster-whisper

Write-Host "`n== Studio (Remotion project) =="
$studio = Join-Path $HOME 'what-if-studio'
if (-not (Test-Path $studio)) { Copy-Item -Recurse (Join-Path $PSScriptRoot 'studio') $studio }
Push-Location $studio; npm install; Pop-Location

Write-Host "`n== Check =="
Refresh
foreach ($c in @('node','npm','ffmpeg','ffprobe')) { if (Have $c) { Write-Host "OK  $c" } else { Write-Host "MISSING $c (restart the PC and run again)" } }
& $py -c "import numpy, PIL, piper, faster_whisper; print('OK  python packages')"
if (Test-Path (Join-Path $studio 'node_modules')) { Write-Host "OK  studio at $studio" } else { Write-Host "MISSING studio node_modules" }
Stop-Transcript | Out-Null
Write-Host "`nDone. You can close this window."
Read-Host 'Press Enter to close'
