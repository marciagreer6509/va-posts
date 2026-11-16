# Trend Checker - one-paste setup for a Windows PC.
# Run from PowerShell:   $k='<access code>'; irm https://marciagreer6509.github.io/va-posts/trend-checker-setup/setup.ps1 | iex
# Does: Git (if missing) -> saves the repo key -> downloads the repo to Desktop\trend-checker
#       -> Claude Code (if missing) -> Desktop shortcut -> opens Claude in the folder.
$ErrorActionPreference = 'Stop'
function Say($m) { Write-Host ""; Write-Host ">> $m" -ForegroundColor Cyan }
function Fail($m) { Write-Host ""; Write-Host "!! $m" -ForegroundColor Red; Read-Host "Press Enter to close"; throw $m }
function RefreshPath { $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User') + ";$env:USERPROFILE\.local\bin" }

if (-not $k) { $k = Read-Host "Paste the access code" }
$k = $k.Trim()

# 1. Git
RefreshPath
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Say "Installing Git (1-3 minutes)..."
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail "winget is missing. Install 'App Installer' from the Microsoft Store, then paste the line again." }
  winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
  RefreshPath
  if (-not (Test-Path "$env:ProgramFiles\Git\cmd\git.exe")) { Fail "Git did not install. Paste the line again, or restart the PC and retry." }
  $env:Path = "$env:ProgramFiles\Git\cmd;$env:Path"
}
Say "Git OK"

# 2. Repo key (works for this one repo only)
$sshDir = Join-Path $env:USERPROFILE '.ssh'
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
$keyFile = Join-Path $sshDir 'trend_checker_key'
try { $pem = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($k)) } catch { Fail "The access code is not complete. Copy the whole line again." }
if ($pem -notmatch 'OPENSSH PRIVATE KEY') { Fail "The access code is not complete. Copy the whole line again." }
if (Test-Path $keyFile) { icacls $keyFile /reset | Out-Null }
[IO.File]::WriteAllText($keyFile, ($pem -replace "`r`n", "`n"))
icacls $keyFile /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null
$sshExe = "$env:ProgramFiles\Git\usr\bin\ssh.exe"
if (-not (Test-Path $sshExe)) { $sshExe = 'ssh' }
$keyFwd = $keyFile -replace '\\','/'
$sshCmd = "`"$($sshExe -replace '\\','/')`" -i `"$keyFwd`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
$env:GIT_SSH_COMMAND = $sshCmd
Say "Key saved"

# 3. Download / update the repo
$desk = [Environment]::GetFolderPath('Desktop')
$dir = Join-Path $desk 'trend-checker'
if (Test-Path (Join-Path $dir '.git')) {
  Say "Updating $dir"
  git -C $dir pull --ff-only
} else {
  Say "Downloading the project to $dir"
  git clone git@github.com:marciagreer6509/trend-checker.git $dir
}
if ($LASTEXITCODE -ne 0) { Fail "Download failed. Check the internet connection and paste the line again." }
git -C $dir config core.sshCommand $sshCmd
git -C $dir config user.name "trend-checker-pc2"
git -C $dir config user.email "trend-checker-pc2@users.noreply.github.com"
Say "Project OK"

# 4. Claude Code
RefreshPath
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Say "Installing Claude Code (1-2 minutes)..."
  Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
  RefreshPath
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Fail "Claude Code did not install. Close this window, open PowerShell again and paste the line again." }
Say "Claude Code OK"

# 5. Desktop shortcut
$lnk = Join-Path $desk 'Trend Checker - Claude.lnk'
$ws = New-Object -ComObject WScript.Shell
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$s.Arguments = "-NoExit -Command `"Set-Location '$dir'; git pull --ff-only; claude`""
$s.WorkingDirectory = $dir
$s.Save()
Say "Shortcut 'Trend Checker - Claude' is on the Desktop"

# 6. Start
Say "Starting Claude in the project. First time only: it opens the browser to sign in to your Claude account."
Set-Location $dir
claude
