#!/usr/bin/env bash
# =============================================================================
# Symdicate Skill Projection — bash (macOS / Linux)
#
# Creates engine-specific copies (or symlinks) of the canonical skills/
# directory so that GitHub Copilot and Google Gemini can discover them in
# their expected locations.
#
#   Copilot expects:  .github/skills/<name>/
#   Gemini  expects:  .agents/skills/<name>/
#   Source of truth:  skills/<name>/SKILL.md
#
# NOTE: This script only manages Symdicate-authored skills from the
# canonical skills/ directory. It does not touch externally subscribed
# content installed by vscode-copilot-sync.
#
# Usage:
#   bash project.sh                    # Project to both engines (copy mode)
#   bash project.sh --engine gemini    # Gemini only
#   bash project.sh --symlink          # Use symlinks instead of copies
#   bash project.sh --clean            # Remove projections
#   bash project.sh --dry-run          # Preview without changes
#
# Options:
#   --engine copilot|gemini|all   Which engine(s) to project for (default: all)
#   --symlink                     Create symlinks instead of copying files
#   --clean                       Remove Symdicate-projected directories
#   --dry-run                     Show what would happen without writing files
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
ENGINE="all"
USE_SYMLINK=0
CLEAN=0
DRY_RUN=0

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --engine)   ENGINE="$2";    shift 2 ;;
        --symlink)  USE_SYMLINK=1;  shift ;;
        --clean)    CLEAN=1;        shift ;;
        --dry-run)  DRY_RUN=1;      shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Validate engine
case "$ENGINE" in
    copilot|gemini|all) ;;
    *) echo "Invalid --engine value '$ENGINE'. Use 'copilot', 'gemini', or 'all'." >&2; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][INFO]    $*"; }
warn() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][WARN]    $*"; }
ok()   { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][SUCCESS] $*"; }
err()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][ERROR]   $*" >&2; }

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
SKILLS_SOURCE="${REPO_ROOT}/skills"

COPILOT_SKILLS="${REPO_ROOT}/.github/skills"
GEMINI_SKILLS="${REPO_ROOT}/.agents/skills"

if [[ ! -d "$SKILLS_SOURCE" ]]; then
    err "Canonical skills/ directory not found at: $SKILLS_SOURCE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Discover skills
# ---------------------------------------------------------------------------
SKILL_DIRS=()
for dir in "$SKILLS_SOURCE"/*/; do
    [[ -d "$dir" ]] || continue
    if [[ -f "${dir}SKILL.md" ]]; then
        SKILL_DIRS+=("$dir")
    fi
done

SKILL_COUNT=${#SKILL_DIRS[@]}
log "Found $SKILL_COUNT skill(s) in skills/"

if [[ $SKILL_COUNT -eq 0 && $CLEAN -eq 0 ]]; then
    warn "No skills found to project. Add a skill to skills/<name>/SKILL.md first."
    exit 0
fi

# ---------------------------------------------------------------------------
# Clean mode
# ---------------------------------------------------------------------------
if [[ $CLEAN -eq 1 ]]; then
    log "Cleaning Symdicate-projected skill directories..."
    removed=0

    for dir in "$SKILLS_SOURCE"/*/; do
        [[ -d "$dir" ]] || continue
        name="$(basename "$dir")"

        if [[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]]; then
            target="${COPILOT_SKILLS}/${name}"
            if [[ -e "$target" ]]; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    warn "  Would remove: $target"
                else
                    rm -rf "$target"
                    ok "  Removed: $target"
                    ((removed++)) || true
                fi
            fi
        fi

        if [[ "$ENGINE" == "gemini" || "$ENGINE" == "all" ]]; then
            target="${GEMINI_SKILLS}/${name}"
            if [[ -e "$target" ]]; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    warn "  Would remove: $target"
                else
                    rm -rf "$target"
                    ok "  Removed: $target"
                    ((removed++)) || true
                fi
            fi
        fi
    done

    # Clean empty parent directories
    if [[ "$ENGINE" == "gemini" || "$ENGINE" == "all" ]]; then
        if [[ -d "$GEMINI_SKILLS" ]] && [[ -z "$(ls -A "$GEMINI_SKILLS" 2>/dev/null)" ]]; then
            [[ $DRY_RUN -eq 0 ]] && rmdir "$GEMINI_SKILLS" 2>/dev/null || true
        fi
        agents_dir="${REPO_ROOT}/.agents"
        if [[ -d "$agents_dir" ]] && [[ -z "$(ls -A "$agents_dir" 2>/dev/null)" ]]; then
            [[ $DRY_RUN -eq 0 ]] && rmdir "$agents_dir" 2>/dev/null || true
        fi
    fi

    if [[ $DRY_RUN -eq 1 ]]; then warn "Dry run complete — no changes made"
    else ok "Clean complete — removed $removed projection(s)"; fi
    exit 0
fi

# ---------------------------------------------------------------------------
# Project function
# ---------------------------------------------------------------------------
project_skill() {
    local source_dir="$1"
    local target_dir="$2"
    local engine_name="$3"

    local skill_name
    skill_name="$(basename "$source_dir")"
    # Remove trailing slash if present
    skill_name="${skill_name%/}"
    local dest_path="${target_dir}/${skill_name}"

    # Remove existing projection to refresh
    if [[ -e "$dest_path" ]]; then
        [[ $DRY_RUN -eq 0 ]] && rm -rf "$dest_path"
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        local mode="copy"
        [[ $USE_SYMLINK -eq 1 ]] && mode="symlink"
        warn "  Would $mode: $skill_name -> $dest_path ($engine_name)"
        return
    fi

    mkdir -p "$target_dir"

    if [[ $USE_SYMLINK -eq 1 ]]; then
        # Remove trailing slash for clean symlink target
        local clean_source="${source_dir%/}"
        if ln -s "$clean_source" "$dest_path" 2>/dev/null; then
            ok "  Linked: $skill_name -> $dest_path ($engine_name)"
        else
            warn "  Symlink failed for $skill_name — falling back to copy."
            cp -r "${source_dir%/}" "$dest_path"
            ok "  Copied (fallback): $skill_name -> $dest_path ($engine_name)"
        fi
    else
        cp -r "${source_dir%/}" "$dest_path"
        ok "  Copied: $skill_name -> $dest_path ($engine_name)"
    fi
}

# ---------------------------------------------------------------------------
# Execute projection
# ---------------------------------------------------------------------------
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN — no files will be written"

if [[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]]; then
    log "Projecting skills to Copilot (.github/skills/)..."
    for dir in "${SKILL_DIRS[@]}"; do
        project_skill "$dir" "$COPILOT_SKILLS" "Copilot"
    done
fi

if [[ "$ENGINE" == "gemini" || "$ENGINE" == "all" ]]; then
    log "Projecting skills to Gemini (.agents/skills/)..."
    for dir in "${SKILL_DIRS[@]}"; do
        project_skill "$dir" "$GEMINI_SKILLS" "Gemini"
    done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry run complete — no changes made"
else
    ok "Projection complete — $SKILL_COUNT skill(s) projected"
    echo ""
    if [[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]]; then
        log "  Copilot: $COPILOT_SKILLS"
    fi
    if [[ "$ENGINE" == "gemini" || "$ENGINE" == "all" ]]; then
        log "  Gemini:  $GEMINI_SKILLS"
    fi
fi
