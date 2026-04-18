<#
.SYNOPSIS
    Install Symdicate agents into VS Code (user-level or repo-level).

.DESCRIPTION
    Downloads the .github/agents/ folder from the Symdicate repository and
    installs it to one of two targets:

      User-level  — agents available in every repo, no .github/ needed
                    Windows : %APPDATA%\Code\User\prompts\
                    macOS   : ~/Library/Application Support/Code/User/prompts/
                    Linux   : ~/.config/Code/User/prompts/

      Repo-level  — agents scoped to the current repository
                    All OS  : <RepoPath>\.github\agents\

.PARAMETER Target
    'user'  — install to VS Code user prompts folder (default)
    'repo'  — install to .github/agents/ in the current (or specified) repo

.PARAMETER RepoPath
    Path to the target repository when using -Target repo.
    Defaults to the current working directory.

.PARAMETER Ref
    Git ref (branch, tag, or commit SHA) to download from.
    Defaults to 'main'. Use a release tag for pinned installs, e.g. 'v1.0.0'.

.PARAMETER Uninstall
    Remove previously installed Symdicate files instead of installing.

.PARAMETER DryRun
    Show what would be installed/removed without writing any files.

.PARAMETER IncludePersonalities
    Also install persona and profile files from personalities/archetypes/, personalities/guests/,
    and personalities/profiles/ (accessibility and wellbeing profiles).
    By default only the agent files (*.agent.md, *.schema.json, *.example.json) are installed.

.EXAMPLE
    # Install to user level (available in all repos)
    irm https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.ps1 | iex

.EXAMPLE
    # Install to current repo
    .\install.ps1 -Target repo

.EXAMPLE
    # Install including persona files to user level
    .\install.ps1 -Target user -IncludePersonalities

.EXAMPLE
    # Dry run — see what would change
    .\install.ps1 -DryRun

.EXAMPLE
    # Uninstall from user level
    .\install.ps1 -Uninstall

.EXAMPLE
    # Pin to a specific release
    .\install.ps1 -Ref v1.0.0
#>
[CmdletBinding(SupportsShouldProcess)] param(
    [ValidateSet('user', 'repo')]
    [string]$Target = 'user',

    [string]$RepoPath = (Get-Location).Path,

    [string]$Ref = 'main',

    [switch]$Uninstall,

    [switch]$DryRun,

    [switch]$IncludePersonalities
)

$ErrorActionPreference = 'Stop'

# Validate -Ref to prevent path traversal or shell injection via crafted ref values
if ($Ref -notmatch '^[a-zA-Z0-9._/\-]+$') {
    throw "Invalid -Ref value '$Ref'. Use a branch name, tag (e.g. v1.0.0), or commit SHA."
}

# Enforce TLS 1.2/1.3 — prevents downgrade on older PowerShell 5.1 / Windows systems
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

#region Helpers

function Log {
    param([string]$Message, [string]$Level = 'INFO')
    $colour = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN' { 'Yellow' }
        'SUCCESS' { 'Green' }
        default { 'Cyan' }
    }
    Write-Host "[$(Get-Date -Format 's')][$Level] $Message" -ForegroundColor $colour
}

function Get-UserPromptsDir {
    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        # Standard VS Code
        $path = Join-Path $env:APPDATA 'Code\User\prompts'
        if (Test-Path (Join-Path $env:APPDATA 'Code - Insiders\User\prompts')) {
            Log "VS Code Insiders detected — installing to Insiders prompts folder" 'WARN'
            return Join-Path $env:APPDATA 'Code - Insiders\User\prompts'
        }
        return $path
    }
    if ($IsMacOS) {
        $base = Join-Path $HOME 'Library/Application Support'
        if (Test-Path (Join-Path $base 'Code - Insiders/User/prompts')) {
            Log "VS Code Insiders detected — installing to Insiders prompts folder" 'WARN'
            return Join-Path $base 'Code - Insiders/User/prompts'
        }
        return Join-Path $base 'Code/User/prompts'
    }
    # Linux / other
    $configBase = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    if (Test-Path (Join-Path $configBase 'Code - Insiders/User/prompts')) {
        Log "VS Code Insiders detected — installing to Insiders prompts folder" 'WARN'
        return Join-Path $configBase 'Code - Insiders/User/prompts'
    }
    return Join-Path $configBase 'Code/User/prompts'
}

function Get-RemoteFileList {
    param([string]$ApiUrl)
    $response = Invoke-RestMethod -Uri $ApiUrl -Headers @{ 'User-Agent' = 'Symdicate-Installer' } -TimeoutSec 30
    return $response
}

function Install-RemoteFile {
    param([string]$RawUrl, [string]$DestPath)

    $destDir = Split-Path $DestPath -Parent
    if (-not $DryRun -and -not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if (Test-Path $DestPath) {
        $existing = (Get-FileHash $DestPath -Algorithm SHA256).Hash
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        $tempFile = Join-Path $tempDir 'download'
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        try {
            Invoke-WebRequest -Uri $RawUrl -OutFile $tempFile -Headers @{ 'User-Agent' = 'Symdicate-Installer' }
            $incoming = (Get-FileHash $tempFile -Algorithm SHA256).Hash
            if ($existing -eq $incoming) {
                Remove-Item $tempDir -Recurse -Force
                return 'unchanged'
            }
            if (-not $DryRun) { Move-Item $tempFile $DestPath -Force }
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            return 'updated'
        }
        catch {
            if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
            throw
        }
    }

    if (-not $DryRun) {
        Invoke-WebRequest -Uri $RawUrl -OutFile $DestPath -Headers @{ 'User-Agent' = 'Symdicate-Installer' }
    }
    return 'added'
}

function Remove-InstalledFile {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return 'not-found' }
    if ($DryRun) { return 'would-remove' }
    Remove-Item $FilePath -Force
    return 'removed'
}

#endregion

#region Resolve install destination

$installDest = if ($Target -eq 'user') {
    Get-UserPromptsDir
}
else {
    Join-Path $RepoPath '.github\agents'
}

if ($DryRun) { Log "DRY RUN — no files will be written" 'WARN' }
Log "Target  : $Target"
Log "Dest    : $installDest"
Log "Ref     : $Ref"

#endregion

#region Build file manifest from GitHub API

$baseApi = "https://api.github.com/repos/CTOUT/Symdicate/contents/.github/agents"
$rawBase = "https://raw.githubusercontent.com/CTOUT/Symdicate/$Ref/.github/agents"

# Files to always install
$agentFiles = @(
    'NeuroGraft.agent.md',
    'profile.schema.json',
    'profile.example.json'
)

# Personality files — fetched dynamically from the API
$personalityFiles = @()
if ($IncludePersonalities) {
    try {
        $archetypes = Get-RemoteFileList "$baseApi/personalities/archetypes?ref=$Ref" |
        Where-Object { $_.type -eq 'file' } |
        ForEach-Object { "personalities/archetypes/$($_.name)" }

        $guests = Get-RemoteFileList "$baseApi/personalities/guests?ref=$Ref" |
        Where-Object { $_.type -eq 'file' } |
        ForEach-Object { "personalities/guests/$($_.name)" }

        $profiles = Get-RemoteFileList "$baseApi/personalities/profiles?ref=$Ref" |
        Where-Object { $_.type -eq 'file' } |
        ForEach-Object { "personalities/profiles/$($_.name)" }

        $personalityFiles = $archetypes + $guests + $profiles

        # Validate API-returned filenames — prevent path traversal via crafted API response
        $personalityFiles = $personalityFiles | Where-Object {
            $_ -match '^personalities/[a-zA-Z0-9_\-]+/[a-zA-Z0-9_.\-]+$'
        }
    }
    catch {
        Log "Could not fetch personality file list from GitHub API — skipping personalities" 'WARN'
    }
}

$allFiles = $agentFiles + $personalityFiles

#endregion

#region Install / Uninstall

$counts = @{ added = 0; updated = 0; unchanged = 0; removed = 0; skipped = 0; 'not-found' = 0; 'would-remove' = 0 }

foreach ($file in $allFiles) {
    $fileName = Split-Path $file -Leaf
    $destPath = Join-Path $installDest $fileName

    # For personalities, preserve subfolder structure at user level
    if ($file -match '^personalities/') {
        $destPath = Join-Path $installDest $file.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    }

    if ($Uninstall) {
        $result = Remove-InstalledFile -FilePath $destPath
        Log "  $result  $destPath"
        $counts[$result]++
    }
    else {
        $rawUrl = "$rawBase/$($file.Replace('\','/'))"
        try {
            $result = Install-RemoteFile -RawUrl $rawUrl -DestPath $destPath
            $symbol = switch ($result) {
                'added' { '+' }
                'updated' { '~' }
                'unchanged' { '=' }
                default { '?' }
            }
            Log "  [$symbol] $destPath  ($result)"
            $counts[$result]++
        }
        catch {
            Log "  FAILED  $destPath  — $_" 'ERROR'
            $counts['skipped']++
        }
    }
}

#endregion

#region Summary

Write-Host ''
if ($Uninstall) {
    Log "Uninstall complete — removed: $($counts['removed'])  not-found: $($counts['not-found'])" 'SUCCESS'
}
elseif ($DryRun) {
    Log "Dry run complete — would add/update files in: $installDest" 'SUCCESS'
}
else {
    Log "Install complete — added: $($counts['added'])  updated: $($counts['updated'])  unchanged: $($counts['unchanged'])  failed: $($counts['skipped'])" 'SUCCESS'

    if ($counts['added'] -gt 0 -or $counts['updated'] -gt 0) {
        Write-Host ''
        if ($Target -eq 'user') {
            Log "Restart VS Code (or reload the window) for the new agents to appear in the agent picker." 'WARN'
        }
        else {
            Log "Agents installed to $installDest — open this repo in VS Code and they will be available immediately." 'WARN'
        }
    }
}

#endregion
