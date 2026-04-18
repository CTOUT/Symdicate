#!/usr/bin/env bash
# =============================================================================
# Symdicate Installer — bash (macOS / Linux)
#
# Installs Symdicate agents into VS Code at user level or repo level.
#
# Usage:
#   # Install to user level (available in all repos) — simplest
#   curl -fsSL https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.sh | bash
#
#   # Install to repo level (.github/agents/ in the current directory)
#   curl -fsSL https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.sh | bash -s -- --target repo
#
#   # Include persona files
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
#   --target user|repo          Install target (default: user)
#   --repo-path <path>          Repo path for --target repo (default: $PWD)
#   --ref <ref>                 Git ref / tag (default: main)
#   --include-personalities     Also install archetype and guest persona files
#   --dry-run                   Show what would happen without writing files
#   --uninstall                 Remove installed Symdicate files
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
TARGET="user"
REPO_PATH="$PWD"
REF="main"
INCLUDE_PERSONALITIES=0
DRY_RUN=0
UNINSTALL=0

OWNER="CTOUT"
REPO="Symdicate"
RAW_BASE="https://raw.githubusercontent.com/${OWNER}/${REPO}"
API_BASE="https://api.github.com/repos/${OWNER}/${REPO}/contents/.github/agents"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)               TARGET="$2";         shift 2 ;;
        --repo-path)            REPO_PATH="$2";      shift 2 ;;
        --ref)                  REF="$2";             shift 2 ;;
        --include-personalities) INCLUDE_PERSONALITIES=1; shift ;;
        --dry-run)              DRY_RUN=1;            shift ;;
        --uninstall)            UNINSTALL=1;          shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][INFO]    $*"; }
warn() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][WARN]    $*"; }
ok()   { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][SUCCESS] $*"; }
err()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')][ERROR]   $*" >&2; }

# ---------------------------------------------------------------------------
# Resolve install destination
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

if [[ "$TARGET" == "user" ]]; then
    INSTALL_DEST="$(get_user_prompts_dir)"
else
    INSTALL_DEST="${REPO_PATH}/.github/agents"
fi

[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN — no files will be written"
log "Target  : $TARGET"
log "Dest    : $INSTALL_DEST"
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
# File manifest
# ---------------------------------------------------------------------------
AGENT_FILES=(
    "NeuroGraft.agent.md"
    "profile.schema.json"
    "profile.example.json"
)

PERSONALITY_FILES=()
if [[ $INCLUDE_PERSONALITIES -eq 1 ]]; then
    if [[ $has_jq -eq 1 ]]; then
        fetch_dir_files() {
            local path="$1"
            curl -fsSL \
                -H "User-Agent: Symdicate-Installer" \
                "${API_BASE}/${path}?ref=${REF}" \
              | jq -r '.[] | select(.type=="file") | .name' 2>/dev/null \
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
            "personalities/profiles/low-load.profile.md"
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

ALL_FILES=("${AGENT_FILES[@]}" "${PERSONALITY_FILES[@]}")

# ---------------------------------------------------------------------------
# Install / uninstall
# ---------------------------------------------------------------------------
added=0; updated=0; unchanged=0; removed=0; failed=0

install_file() {
    local rel_path="$1"
    local file_name
    file_name="$(basename "$rel_path")"
    local dest_path

    if [[ "$rel_path" == personalities/* ]]; then
        dest_path="${INSTALL_DEST}/${rel_path}"
    else
        dest_path="${INSTALL_DEST}/${file_name}"
    fi

    local raw_url="${RAW_BASE}/${REF}/.github/agents/${rel_path}"
    local dest_dir
    dest_dir="$(dirname "$dest_path")"

    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$dest_dir"
    fi

    if [[ -f "$dest_path" ]]; then
        local tmp_file
        tmp_file="$(mktemp)"
        if curl -fsSL -H "User-Agent: Symdicate-Installer" -o "$tmp_file" "$raw_url" 2>/dev/null; then
            local src_hash dst_hash
            src_hash="$(sha256sum "$tmp_file" 2>/dev/null || shasum -a 256 "$tmp_file" 2>/dev/null | awk '{print $1}')"
            dst_hash="$(sha256sum "$dest_path" 2>/dev/null || shasum -a 256 "$dest_path" 2>/dev/null | awk '{print $1}')"
            if [[ "$src_hash" == "$dst_hash" ]]; then
                rm -f "$tmp_file"
                log "  [=] $dest_path  (unchanged)"
                ((unchanged++)) || true  # arithmetic '0' exit code is not an error
            else
                if [[ $DRY_RUN -eq 0 ]]; then mv "$tmp_file" "$dest_path"; else rm -f "$tmp_file"; fi
                log "  [~] $dest_path  (updated)"
                ((updated++)) || true  # arithmetic '0' exit code is not an error
            fi
        else
            rm -f "$tmp_file"
            err "  FAILED  $raw_url"
            ((failed++)) || true  # arithmetic '0' exit code is not an error
        fi
    else
        if [[ $DRY_RUN -eq 0 ]]; then
            if curl -fsSL -H "User-Agent: Symdicate-Installer" -o "$dest_path" "$raw_url" 2>/dev/null; then
                log "  [+] $dest_path  (added)"
                ((added++)) || true  # arithmetic '0' exit code is not an error
            else
                err "  FAILED  $raw_url"
                ((failed++)) || true  # arithmetic '0' exit code is not an error
            fi
        else
            log "  [+] $dest_path  (would add)"
            ((added++)) || true  # arithmetic '0' exit code is not an error
        fi
    fi
}

remove_file() {
    local rel_path="$1"
    local file_name
    file_name="$(basename "$rel_path")"
    local dest_path

    if [[ "$rel_path" == personalities/* ]]; then
        dest_path="${INSTALL_DEST}/${rel_path}"
    else
        dest_path="${INSTALL_DEST}/${file_name}"
    fi

    if [[ -f "$dest_path" ]]; then
        if [[ $DRY_RUN -eq 0 ]]; then rm -f "$dest_path"; fi
        log "  removed  $dest_path"
        ((removed++)) || true
    else
        log "  not-found  $dest_path"
    fi
}

for file in "${ALL_FILES[@]}"; do
    if [[ $UNINSTALL -eq 1 ]]; then
        remove_file "$file"
    else
        install_file "$file"
    fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [[ $UNINSTALL -eq 1 ]]; then
    ok "Uninstall complete — removed: ${removed}"
elif [[ $DRY_RUN -eq 1 ]]; then
    ok "Dry run complete — would install to: ${INSTALL_DEST}"
else
    ok "Install complete — added: ${added}  updated: ${updated}  unchanged: ${unchanged}  failed: ${failed}"
    if [[ $((added + updated)) -gt 0 ]]; then
        echo ""
        if [[ "$TARGET" == "user" ]]; then
            warn "Restart VS Code (or reload the window) for the new agents to appear in the agent picker."
        else
            warn "Agents installed to ${INSTALL_DEST} — open this repo in VS Code and they will be available immediately."
        fi
    fi
fi
