param(
  [Parameter(Mandatory=$true)][string]$TargetDir,
  [Parameter(Mandatory=$true)][string]$WireMudderOriginUrl
)
$ErrorActionPreference = "Stop"
if (Test-Path $TargetDir) { throw "Target directory already exists" }
$PackRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
git clone https://github.com/Mudlet/Mudlet.git $TargetDir
Push-Location $TargetDir
git switch -c wire/development 77086c295f4adf59197e586e689d19bdde8e1008
git remote rename origin upstream
git remote add origin $WireMudderOriginUrl
Get-ChildItem -Force $PackRoot | Copy-Item -Destination . -Recurse -Force
sh scripts/validate-blueprint.sh
Pop-Location
Write-Output "bootstrap fork: ok"
