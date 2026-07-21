#!/usr/bin/env bash
# =============================================================================
# Symdicate Installer — bash (macOS / Linux)
#
# Installs Symdicate agents and skills into VS Code or Gemini.
#
# Usage:
#   # Install agents to user level (Copilot, available in all repos)
#   curl -fsSL https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.sh | bash
#
#   # Install to repo level (.github/agents/ in the current directory)
#   curl -fsSL https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.sh | bash -s -- --target repo
#
#   # Install skills to Gemini
#   bash install.sh --engine gemini
#
#   # Install to both engines
#   bash install.sh --engine all --include-skills
#
#   # Include persona files (Copilot only)
#   bash install.sh --target user --include-personalities
#
#   # Pin to a release
#   bash install.sh --ref v1.0.0
#
#   # Dry run
#   bash install.sh --dry-run
#
#   # Uninstall
#   bash install.sh --uninstall
#
# Options:
#   --target user|repo          Install target for Copilot (default: user)
#   --engine copilot|gemini|all Engine target (default: copilot)
#   --repo-path <path>          Repo path for --target repo (default: $PWD)
#   --ref <ref>                 Git ref / tag (default: main)
#   --include-personalities     Also install archetype and guest persona files (Copilot only)
#   --include-skills            Also install Symdicate-authored skills from skills/
#   --dry-run                   Show what would happen without writing files
#   --uninstall                 Remove installed Symdicate files
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
TARGET="user"
ENGINE="copilot"
REPO_PATH="$PWD"
REF="main"
INCLUDE_PERSONALITIES=0
INCLUDE_SKILLS=0
DRY_RUN=0
UNINSTALL=0

OWNER="CTOUT"
REPO="Symdicate"
RAW_BASE="https://raw.githubusercontent.com/${OWNER}/${REPO}"
AGENTS_API="https://api.github.com/repos/${OWNER}/${REPO}/contents/.github/agents"
SKILLS_API="https://api.github.com/repos/${OWNER}/${REPO}/contents/skills"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)               TARGET="$2";         shift 2 ;;
        --engine)               ENGINE="$2";         shift 2 ;;
        --repo-path)            REPO_PATH="$2";      shift 2 ;;
        --ref)                  REF="$2";             shift 2 ;;
        --include-personalities) INCLUDE_PERSONALITIES=1; shift ;;
        --include-skills)       INCLUDE_SKILLS=1;     shift ;;
        --dry-run)              DRY_RUN=1;            shift ;;
        --uninstall)            UNINSTALL=1;          shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Validate ENGINE
case "$ENGINE" in
    copilot|gemini|all) ;;
    *) echo "Invalid --engine value '$ENGINE'. Use 'copilot', 'gemini', or 'all'." >&2; exit 1 ;;
esac

# When engine is gemini-only, skills are always included
[[ "$ENGINE" == "gemini" ]] && INCLUDE_SKILLS=1

# Validate REF — prevent path traversal or injection via crafted ref values
if [[ ! "$REF" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    err "Invalid --ref value '$REF'. Use a branch name, tag (e.g. v1.0.0), or commit SHA."
    exit 1
fi

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][INFO]    $*"; }
warn() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][WARN]    $*"; }
ok()   { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][SUCCESS] $*"; }
err()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][ERROR]   $*" >&2; }

# ---------------------------------------------------------------------------
# Resolve install destinations
# ---------------------------------------------------------------------------
get_user_prompts_dir() {
    case "$(uname -s)" in
        Darwin)
            local base="$HOME/Library/Application Support"
            if [[ -d "$base/Code - Insiders/User/prompts" ]]; then
                warn "VS Code Insiders detected — using Insiders prompts folder"
                echo "$base/Code - Insiders/User/prompts"
            else
                echo "$base/Code/User/prompts"
            fi
            ;;
        Linux|*)
            local config_base="${XDG_CONFIG_HOME:-$HOME/.config}"
            if [[ -d "$config_base/Code - Insiders/User/prompts" ]]; then
                warn "VS Code Insiders detected — using Insiders prompts folder"
                echo "$config_base/Code - Insiders/User/prompts"
            elif [[ -d "$config_base/Code/User/prompts" ]]; then
                echo "$config_base/Code/User/prompts"
            else
                # Cursor support
                if [[ -d "$HOME/.cursor/User/prompts" ]]; then
                    warn "Cursor detected — using Cursor prompts folder"
                    echo "$HOME/.cursor/User/prompts"
                else
                    echo "$config_base/Code/User/prompts"
                fi
            fi
            ;;
    esac
}

get_gemini_skills_dir() {
    echo "$HOME/.gemini/config/skills"
}

# Copilot destination
if [[ "$TARGET" == "user" ]]; then
    COPILOT_DEST="$(get_user_prompts_dir)"
else
    COPILOT_DEST="${REPO_PATH}/.github/agents"
fi

# Gemini destination
GEMINI_DEST="$(get_gemini_skills_dir)"

[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN — no files will be written"
log "Engine  : $ENGINE"
log "Target  : $TARGET"
[[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]] && log "Copilot : $COPILOT_DEST"
[[ "$ENGINE" == "gemini"  || "$ENGINE" == "all" ]] && log "Gemini  : $GEMINI_DEST"
log "Ref     : $REF"

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
if ! command -v curl &>/dev/null; then
    err "curl is required but not installed."
    exit 1
fi

has_jq=0
command -v jq &>/dev/null && has_jq=1

# ---------------------------------------------------------------------------
# File manifest — Copilot agents
# ---------------------------------------------------------------------------
AGENT_FILES=(
    "NeuroGraft.agent.md"
    "Fetch.agent.md"
    "profile.schema.json"
    "profile.example.json"
    "Imprint.schema.json"
    "Imprint.example.json"
)

PERSONALITY_FILES=()
if [[ $INCLUDE_PERSONALITIES -eq 1 && ("$ENGINE" == "copilot" || "$ENGINE" == "all") ]]; then
    if [[ $has_jq -eq 1 ]]; then
        fetch_dir_files() {
            local path="$1"
            curl -fsSL \
                -H "User-Agent: Symdicate-Installer" \
                "${AGENTS_API}/${path}?ref=${REF}" \
              | jq -r '.[] | select(.type=="file") | .name' 2>/dev/null \
              | grep -E '^[a-zA-Z0-9_.\-]+$' \
              | while read -r name; do echo "${path}/${name}"; done
        }
        while IFS= read -r f; do PERSONALITY_FILES+=("$f"); done < <(fetch_dir_files "personalities/archetypes")
        while IFS= read -r f; do PERSONALITY_FILES+=("$f"); done < <(fetch_dir_files "personalities/guests")
        while IFS= read -r f; do PERSONALITY_FILES+=("$f"); done < <(fetch_dir_files "personalities/profiles")
    else
        warn "jq not found — falling back to known personality file list."
        warn "Install jq for dynamic personality discovery: https://jqlang.github.io/jq/"
        PERSONALITY_FILES=(
            "personalities/archetypes/_TEMPLATE.archetype.md"
            "personalities/archetypes/bureaucrat.persona.md"
            "personalities/archetypes/child.persona.md"
            "personalities/archetypes/comedian.persona.md"
            "personalities/archetypes/detective.persona.md"
            "personalities/archetypes/mentor.persona.md"
            "personalities/archetypes/philosopher.persona.md"
            "personalities/archetypes/pirate.persona.md"
            "personalities/archetypes/poet.persona.md"
            "personalities/archetypes/robot.persona.md"
            "personalities/archetypes/scientist.persona.md"
            "personalities/archetypes/stoic.persona.md"
            "personalities/guests/_TEMPLATE.guest.md"
            "personalities/guests/data.guest.md"
            "personalities/guests/glados.guest.md"
            "personalities/guests/hermione-granger.guest.md"
            "personalities/guests/jack-sparrow.guest.md"
            "personalities/guests/wednesday-addams.guest.md"
            "personalities/profiles/_TEMPLATE.profile.md"
            "personalities/profiles/direct.profile.md"
            "personalities/profiles/spacious.profile.md"
            "personalities/profiles/mental-health.profile.md"
            "personalities/profiles/structured.profile.md"
            "personalities/profiles/high-context.profile.md"
            "personalities/profiles/dyscalculia.profile.md"
            "personalities/profiles/screen-reader.profile.md"
            "personalities/profiles/eal.profile.md"
            "personalities/profiles/dyslexia.profile.md"
            "personalities/profiles/dyspraxia.profile.md"
            "personalities/profiles/anxiety.profile.md"
            "personalities/profiles/depression.profile.md"
            "personalities/profiles/stress.profile.md"
            "personalities/profiles/cognitive-fatigue.profile.md"
        )
    fi
fi

COPILOT_FILES=("${AGENT_FILES[@]}" "${PERSONALITY_FILES[@]}")

# ---------------------------------------------------------------------------
# File manifest — Skills (both engines)
# ---------------------------------------------------------------------------
SKILL_ENTRIES=()  # Formatted as "skill_name/filename"
if [[ $INCLUDE_SKILLS -eq 1 ]]; then
    if [[ $has_jq -eq 1 ]]; then
        # Discover skill directories from the API
        skill_dirs=$(curl -fsSL \
            -H "User-Agent: Symdicate-Installer" \
            "${SKILLS_API}?ref=${REF}" 2>/dev/null \
          | jq -r '.[] | select(.type=="dir") | .name' 2>/dev/null \
          | grep -E '^[a-zA-Z0-9_-]+$')

        for skill_name in $skill_dirs; do
            # List files in each skill directory
            skill_files=$(curl -fsSL \
                -H "User-Agent: Symdicate-Installer" \
                "${SKILLS_API}/${skill_name}?ref=${REF}" 2>/dev/null \
              | jq -r '.[] | select(.type=="file") | .name' 2>/dev/null \
              | grep -E '^[a-zA-Z0-9_.\-]+$')

            has_skill_md=0
            for sf in $skill_files; do
                [[ "$sf" == "SKILL.md" ]] && has_skill_md=1
            done

            if [[ $has_skill_md -eq 1 ]]; then
                for sf in $skill_files; do
                    SKILL_ENTRIES+=("${skill_name}/${sf}")
                done
            fi
        done
        log "Found ${#SKILL_ENTRIES[@]} skill file(s) to install"
    else
        warn "jq not found — cannot discover skills dynamically. Install jq for skill support."
    fi
fi

# ---------------------------------------------------------------------------
# Install / uninstall
# ---------------------------------------------------------------------------
added=0; updated=0; unchanged=0; removed=0; failed=0

install_file() {
    local rel_path="$1"
    local dest_base="$2"
    local raw_base_url="$3"
    local file_name
    file_name="$(basename "$rel_path")"
    local dest_path

    if [[ "$rel_path" == personalities/* || "$rel_path" == */SKILL.md || "$rel_path" == */* ]]; then
        dest_path="${dest_base}/${rel_path}"
    else
        dest_path="${dest_base}/${file_name}"
    fi

    local raw_url="${raw_base_url}/${rel_path}"
    local dest_dir
    dest_dir="$(dirname "$dest_path")"

    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$dest_dir"
    fi

    if [[ -f "$dest_path" ]]; then
        local tmp_dir tmp_file
        tmp_dir="$(mktemp -d)"
        tmp_file="${tmp_dir}/download"
        if curl -fsSL -H "User-Agent: Symdicate-Installer" -o "$tmp_file" "$raw_url" 2>/dev/null; then
            local src_hash dst_hash
            src_hash="$(sha256sum "$tmp_file" 2>/dev/null || shasum -a 256 "$tmp_file" 2>/dev/null | awk '{print $1}')"
            dst_hash="$(sha256sum "$dest_path" 2>/dev/null || shasum -a 256 "$dest_path" 2>/dev/null | awk '{print $1}')"
            if [[ "$src_hash" == "$dst_hash" ]]; then
                rm -rf "$tmp_dir"
                log "  [=] $dest_path  (unchanged)"
                ((unchanged++)) || true
            else
                if [[ $DRY_RUN -eq 0 ]]; then mv "$tmp_file" "$dest_path" && rm -rf "$tmp_dir"; else rm -rf "$tmp_dir"; fi
                log "  [~] $dest_path  (updated)"
                ((updated++)) || true
            fi
        else
            rm -rf "$tmp_dir"
            err "  FAILED  $raw_url"
            ((failed++)) || true
        fi
    else
        if [[ $DRY_RUN -eq 0 ]]; then
            if curl -fsSL -H "User-Agent: Symdicate-Installer" -o "$dest_path" "$raw_url" 2>/dev/null; then
                log "  [+] $dest_path  (added)"
                ((added++)) || true
            else
                err "  FAILED  $raw_url"
                ((failed++)) || true
            fi
        else
            log "  [+] $dest_path  (would add)"
            ((added++)) || true
        fi
    fi
}

remove_file() {
    local rel_path="$1"
    local dest_base="$2"
    local file_name
    file_name="$(basename "$rel_path")"
    local dest_path

    if [[ "$rel_path" == personalities/* || "$rel_path" == */* ]]; then
        dest_path="${dest_base}/${rel_path}"
    else
        dest_path="${dest_base}/${file_name}"
    fi

    if [[ -f "$dest_path" ]]; then
        if [[ $DRY_RUN -eq 0 ]]; then rm -f "$dest_path"; fi
        log "  removed  $dest_path"
        ((removed++)) || true
    else
        log "  not-found  $dest_path"
    fi
}

AGENTS_RAW="${RAW_BASE}/${REF}/.github/agents"
SKILLS_RAW="${RAW_BASE}/${REF}/skills"

# --- Copilot: agents + personalities ---
if [[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]]; then
    log "Installing Copilot agents..."
    for file in "${COPILOT_FILES[@]}"; do
        if [[ $UNINSTALL -eq 1 ]]; then
            remove_file "$file" "$COPILOT_DEST"
        else
            install_file "$file" "$COPILOT_DEST" "$AGENTS_RAW"
        fi
    done
fi

# --- Skills (both engines) ---
if [[ ${#SKILL_ENTRIES[@]} -gt 0 ]]; then
    if [[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]]; then
        # Copilot skill destination
        if [[ "$TARGET" == "user" ]]; then
            COPILOT_SKILL_DEST="$(dirname "$COPILOT_DEST")/skills"
        else
            COPILOT_SKILL_DEST="$(dirname "$(dirname "$COPILOT_DEST")")/.github/skills"
        fi
        log "Installing skills to Copilot ($COPILOT_SKILL_DEST)..."
        for entry in "${SKILL_ENTRIES[@]}"; do
            if [[ $UNINSTALL -eq 1 ]]; then
                remove_file "$entry" "$COPILOT_SKILL_DEST"
            else
                install_file "$entry" "$COPILOT_SKILL_DEST" "$SKILLS_RAW"
            fi
        done
    fi

    if [[ "$ENGINE" == "gemini" || "$ENGINE" == "all" ]]; then
        log "Installing skills to Gemini ($GEMINI_DEST)..."
        for entry in "${SKILL_ENTRIES[@]}"; do
            if [[ $UNINSTALL -eq 1 ]]; then
                remove_file "$entry" "$GEMINI_DEST"
            else
                install_file "$entry" "$GEMINI_DEST" "$SKILLS_RAW"
            fi
        done
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [[ $UNINSTALL -eq 1 ]]; then
    ok "Uninstall complete — removed: ${removed}"
elif [[ $DRY_RUN -eq 1 ]]; then
    ok "Dry run complete — engine: ${ENGINE}"
else
    ok "Install complete — added: ${added}  updated: ${updated}  unchanged: ${unchanged}  failed: ${failed}"
    if [[ $((added + updated)) -gt 0 ]]; then
        echo ""
        if [[ "$ENGINE" == "copilot" || "$ENGINE" == "all" ]]; then
            if [[ "$TARGET" == "user" ]]; then
                warn "Restart VS Code (or reload the window) for the new agents to appear in the agent picker."
            else
                warn "Agents installed to ${COPILOT_DEST} — open this repo in VS Code and they will be available immediately."
            fi
        fi
        if [[ "$ENGINE" == "gemini" || "$ENGINE" == "all" ]]; then
            warn "Gemini skills installed to ${GEMINI_DEST} — they will be available in your next Gemini session."
        fi
    fi
fi
