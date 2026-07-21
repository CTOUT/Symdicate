<#
.SYNOPSIS
    Project canonical skills into engine-specific directories.

.DESCRIPTION
    Creates engine-specific copies (or symlinks) of the canonical skills/
    directory so that GitHub Copilot and Google Gemini can discover them in
    their expected locations.

    Copilot expects:  .github/skills/<name>/
    Gemini  expects:  .agents/skills/<name>/

    Source of truth:  skills/<name>/SKILL.md

    By default, files are copied. Use -Symlink to create directory symlinks
    instead (requires elevated permissions on Windows, or Developer Mode).

    NOTE: This script only manages Symdicate-authored skills from the
    canonical skills/ directory. It does not touch externally subscribed
    content installed by vscode-copilot-sync.

.PARAMETER Engine
    Which engine(s) to project for: 'copilot', 'gemini', or 'all' (default).

.PARAMETER Symlink
    Create directory symlinks instead of copying files. Requires elevated
    permissions on Windows (or Developer Mode enabled). On macOS/Linux,
    symlinks work without elevation.

.PARAMETER Clean
    Remove all Symdicate-projected directories without recreating them.
    Does not affect externally subscribed skills.

.PARAMETER DryRun
    Show what would be created or removed without making changes.

.EXAMPLE
    # Project to both engines (copy mode)
    .\project.ps1

.EXAMPLE
    # Project to Gemini only using symlinks
    .\project.ps1 -Engine gemini -Symlink

.EXAMPLE
    # Remove all projections
    .\project.ps1 -Clean

.EXAMPLE
    # Dry run — see what would change
    .\project.ps1 -DryRun
#>
[CmdletBinding(SupportsShouldProcess)] param(
    [ValidateSet('copilot', 'gemini', 'all')]
    [string]$Engine = 'all',

    [switch]$Symlink,
    [switch]$Clean,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

#region Helpers

function Log {
    param([string]$Message, [string]$Level = 'INFO')
    $colour = switch ($Level) {
        'ERROR'   { 'Red' }
        'WARN'    { 'Yellow' }
        'SUCCESS' { 'Green' }
        default   { 'Cyan' }
    }
    Write-Host "[$(Get-Date -Format 's')][$Level] $Message" -ForegroundColor $colour
}

#endregion

#region Resolve paths

$repoRoot = $PSScriptRoot
$skillsSource = Join-Path $repoRoot 'skills'

# Engine-specific projection targets
$copilotSkills = Join-Path $repoRoot '.github' 'skills'
$geminiSkills  = Join-Path $repoRoot '.agents' 'skills'

if (-not (Test-Path $skillsSource)) {
    Log "Canonical skills/ directory not found at: $skillsSource" 'ERROR'
    exit 1
}

#endregion

#region Discover skills

$skillDirs = Get-ChildItem -Path $skillsSource -Directory | Where-Object {
    # Each skill must contain a SKILL.md
    Test-Path (Join-Path $_.FullName 'SKILL.md')
}

$skillCount = ($skillDirs | Measure-Object).Count
Log "Found $skillCount skill(s) in skills/"

if ($skillCount -eq 0 -and -not $Clean) {
    Log 'No skills found to project. Add a skill to skills/<name>/SKILL.md first.' 'WARN'
    exit 0
}

#endregion

#region Clean mode

if ($Clean) {
    Log 'Cleaning Symdicate-projected skill directories...'

    # Only remove skills that exist in our canonical source — never touch
    # externally subscribed content from vscode-copilot-sync.
    $canonicalNames = Get-ChildItem -Path $skillsSource -Directory | ForEach-Object { $_.Name }

    $removedCount = 0

    foreach ($name in $canonicalNames) {
        if ($Engine -in 'copilot', 'all') {
            $target = Join-Path $copilotSkills $name
            if (Test-Path $target) {
                if ($DryRun) { Log "  Would remove: $target" 'WARN' }
                else { Remove-Item $target -Recurse -Force; Log "  Removed: $target" 'SUCCESS'; $removedCount++ }
            }
        }
        if ($Engine -in 'gemini', 'all') {
            $target = Join-Path $geminiSkills $name
            if (Test-Path $target) {
                if ($DryRun) { Log "  Would remove: $target" 'WARN' }
                else { Remove-Item $target -Recurse -Force; Log "  Removed: $target" 'SUCCESS'; $removedCount++ }
            }
        }
    }

    # Clean the .agents/skills/ parent directory if it's now empty
    if ($Engine -in 'gemini', 'all') {
        $agentsDir = Join-Path $repoRoot '.agents'
        if ((Test-Path $geminiSkills) -and (Get-ChildItem $geminiSkills | Measure-Object).Count -eq 0) {
            if (-not $DryRun) { Remove-Item $geminiSkills -Force }
        }
        if ((Test-Path $agentsDir) -and (Get-ChildItem $agentsDir | Measure-Object).Count -eq 0) {
            if (-not $DryRun) { Remove-Item $agentsDir -Force }
        }
    }

    if ($DryRun) { Log 'Dry run complete — no changes made' 'WARN' }
    else { Log "Clean complete — removed $removedCount projection(s)" 'SUCCESS' }
    exit 0
}

#endregion

#region Project function

function Project-SkillDir {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$EngineName
    )

    $skillName = Split-Path $SourceDir -Leaf
    $destPath = Join-Path $TargetDir $skillName

    if (Test-Path $destPath) {
        # Remove existing projection to refresh
        if (-not $DryRun) { Remove-Item $destPath -Recurse -Force }
    }

    if ($DryRun) {
        $mode = if ($Symlink) { 'symlink' } else { 'copy' }
        Log "  Would $mode`: $skillName -> $destPath ($EngineName)" 'WARN'
        return
    }

    $parentDir = Split-Path $destPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if ($Symlink) {
        try {
            New-Item -ItemType SymbolicLink -Path $destPath -Target $SourceDir -Force | Out-Null
            Log "  Linked: $skillName -> $destPath ($EngineName)" 'SUCCESS'
        }
        catch {
            Log "  Symlink failed for $skillName — falling back to copy. Error: $_" 'WARN'
            Log '  Tip: On Windows, run as Administrator or enable Developer Mode for symlink support.' 'WARN'
            Copy-Item -Path $SourceDir -Destination $destPath -Recurse -Force
            Log "  Copied (fallback): $skillName -> $destPath ($EngineName)" 'SUCCESS'
        }
    }
    else {
        Copy-Item -Path $SourceDir -Destination $destPath -Recurse -Force
        Log "  Copied: $skillName -> $destPath ($EngineName)" 'SUCCESS'
    }
}

#endregion

#region Execute projection

if ($DryRun) { Log 'DRY RUN — no files will be written' 'WARN' }

if ($Engine -in 'copilot', 'all') {
    Log 'Projecting skills to Copilot (.github/skills/)...'
    foreach ($dir in $skillDirs) {
        Project-SkillDir -SourceDir $dir.FullName -TargetDir $copilotSkills -EngineName 'Copilot'
    }
}

if ($Engine -in 'gemini', 'all') {
    Log 'Projecting skills to Gemini (.agents/skills/)...'
    foreach ($dir in $skillDirs) {
        Project-SkillDir -SourceDir $dir.FullName -TargetDir $geminiSkills -EngineName 'Gemini'
    }
}

#endregion

#region Summary

Write-Host ''
if ($DryRun) {
    Log 'Dry run complete — no changes made' 'WARN'
} else {
    Log "Projection complete — $skillCount skill(s) projected" 'SUCCESS'
    Write-Host ''
    if ($Engine -in 'copilot', 'all') {
        Log "  Copilot: $copilotSkills"
    }
    if ($Engine -in 'gemini', 'all') {
        Log "  Gemini:  $geminiSkills"
    }
}

#endregion
