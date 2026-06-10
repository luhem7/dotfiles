#!/usr/bin/env bash
#
# claude-code-compromise-check.sh
# -------------------------------
# Read-only detector for the June 2026 "Miasma" / TeamPCP npm supply-chain
# campaign and related Claude Code SessionStart-hook backdoors (incl. the
# "Phantom Gyp" binding.gyp second wave and the supabase/microsoft typosquats).
#
# *** DETECTION ONLY ***
# This script NEVER deletes, edits, quarantines, or transmits anything. It only
# reads files and prints findings. This is deliberate: the malware in this
# campaign booby-traps cleanup — if it sees its credentials being revoked while
# it is still resident, it can wipe and overwrite your home directory. So the
# correct order is: DETECT (this script) -> DISCONNECT network -> CLEAN
# persistence by hand -> ROTATE every secret FROM A DIFFERENT, TRUSTED MACHINE.
#
# Usage:
#   ./claude-code-compromise-check.sh [SCAN_ROOT ...]
# Defaults to scanning $HOME if no roots are given. Pass specific project dirs
# to scan faster, e.g.:
#   ./claude-code-compromise-check.sh ~/workspace ~/projects
#
# Exit codes: 0 = nothing found, 1 = REVIEW items only, 2 = HIGH-severity hit.
#
# IOC sources (June 2026 advisories):
#   Microsoft Threat Intelligence, Snyk, StepSecurity, SafeDep, Trend Micro.

set -uo pipefail

# ---------------------------------------------------------------------------
# Scan roots
# ---------------------------------------------------------------------------
if [ "$#" -gt 0 ]; then
  SCAN_ROOTS=("$@")
else
  SCAN_ROOTS=("$HOME")
fi

# Directories that are large and irrelevant — pruned to keep the scan fast.
# (node_modules is intentionally NOT pruned: that is where binding.gyp,
#  oversized index.js, and planted .claude/.vscode dirs hide.)
PRUNE_NAMES=(.git .cache .cargo .rustup .npm-cache .gradle .m2 Steam .steam
             Trash .thumbnails .local/share/Trash go/pkg .pyenv .nvm/versions)

# ---------------------------------------------------------------------------
# Indicators of Compromise
# ---------------------------------------------------------------------------

# Affected / weaponized npm package names + scopes (substring match in lockfiles).
BAD_PACKAGES=(
  "@redhat-cloud-services/"
  "@vapi-ai/server-sdk"
  "ai-sdk-ollama"
  "autotel"
  "awaitly"
  "executable-stories"
  "node-env-resolver"
  "wrangler-deploy"
  # SafeDep typosquats (fake "superbase" / "micresoft" publishers)
  "supabase-javascript"
  "iceberg-javascript"
  "auth-javascript"
  "ms-graph-types"
  "microsoft-applicationinsights-common"
)

# High-confidence strings that should never appear inside an editor hook/config.
HIGH_STR_PATTERNS='setup\.mjs|setup\.js|oven-sh/bun|bun-linux|thebeautifulmarchoftime|IfYouInvalidateThisToken|Shai-Hulud|niagA oG eW|Miasma|liuende501|207\.90\.194\.2|git-service\.com|m-kosche\.com|169\.254\.169\.254'

# C2 network indicators (also checked against /etc/hosts and live sockets).
C2_IPS=("207.90.194.2")
C2_DOMAINS=("check.git-service.com" "git-service.com" "t.m-kosche.com" "m-kosche.com")

# Known-bad file hashes.
BAD_ELF_MD5="b604b21749a396111bb111d46d97b1c4"
BAD_BINDING_SHA256="ef641e956f91d501b748085996303c96a64d67f63bfeef0dda175e5aa19cca90"

# Global Claude config locations to always inspect.
CLAUDE_CONFIGS=(
  "$HOME/.claude.json"
  "$HOME/.claude/settings.json"
  "$HOME/.config/claude/settings.json"
)

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  C_RED=$'\033[1;31m'; C_YEL=$'\033[1;33m'; C_GRN=$'\033[1;32m'
  C_DIM=$'\033[2m'; C_BLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_RED=""; C_YEL=""; C_GRN=""; C_DIM=""; C_BLD=""; C_RST=""
fi

HIGH_COUNT=0
REVIEW_COUNT=0

high()   { HIGH_COUNT=$((HIGH_COUNT+1));   printf '%s[HIGH]%s   %s\n' "$C_RED" "$C_RST" "$*"; }
review() { REVIEW_COUNT=$((REVIEW_COUNT+1)); printf '%s[REVIEW]%s %s\n' "$C_YEL" "$C_RST" "$*"; }
ok()     { printf '%s[ ok ]%s   %s\n' "$C_GRN" "$C_RST" "$*"; }
section(){ printf '\n%s== %s ==%s\n' "$C_BLD" "$*" "$C_RST"; }
note()   { printf '%s  %s%s\n' "$C_DIM" "$*" "$C_RST"; }

# Build the shared find prune expression once.
build_prune() {
  local first=1
  PRUNE_EXPR=()
  PRUNE_EXPR+=( '(' )
  for n in "${PRUNE_NAMES[@]}"; do
    if [ "$first" -eq 1 ]; then first=0; else PRUNE_EXPR+=( -o ); fi
    PRUNE_EXPR+=( -name "$n" )
  done
  PRUNE_EXPR+=( ')' -prune -o )
}

# find wrapper: find_files <find-args...> -> prints matching paths, pruned.
find_files() {
  find "${SCAN_ROOTS[@]}" "${PRUNE_EXPR[@]}" "$@" 2>/dev/null
}

# ---------------------------------------------------------------------------
section "Scan configuration"
# ---------------------------------------------------------------------------
note "Scan roots: ${SCAN_ROOTS[*]}"
HAS_JQ=0; command -v jq >/dev/null 2>&1 && HAS_JQ=1
[ "$HAS_JQ" -eq 1 ] && note "jq found — using structured JSON parsing for hooks." \
                    || note "jq NOT found — falling back to text matching for hooks."
build_prune

# ---------------------------------------------------------------------------
section "1. Claude Code config & SessionStart hooks (persistence)"
# ---------------------------------------------------------------------------
# Gather global configs + every project-level .claude/settings*.json under roots.
claude_files=()
for f in "${CLAUDE_CONFIGS[@]}"; do [ -f "$f" ] && claude_files+=("$f"); done
while IFS= read -r f; do [ -n "$f" ] && claude_files+=("$f"); done < <(
  find_files -type f \( -path '*/.claude/settings.json' -o -path '*/.claude/settings.local.json' \) -print
)

if [ "${#claude_files[@]}" -eq 0 ]; then
  ok "No Claude config files found under scan roots."
else
  before=$((HIGH_COUNT+REVIEW_COUNT))
  for f in "${claude_files[@]}"; do
    # Extract every "command" string anywhere in the JSON, plus note hook events.
    cmds=""
    if [ "$HAS_JQ" -eq 1 ]; then
      cmds=$(jq -r '.. | objects | .command? // empty' "$f" 2>/dev/null)
    else
      cmds=$(grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null)
    fi

    # HIGH: any command string matching a known-bad pattern.
    bad=$(printf '%s\n' "$cmds" | grep -iE "$HIGH_STR_PATTERNS" 2>/dev/null)
    if [ -n "$bad" ]; then
      high "Malicious hook command in: $f"
      printf '%s' "$bad" | sed 's/^/         > /'
    fi

    # REVIEW: a SessionStart hook exists (legit or not — eyeball it).
    if grep -q '"SessionStart"' "$f" 2>/dev/null; then
      if [ -z "$bad" ]; then
        review "SessionStart hook present (verify it is yours): $f"
        if [ "$HAS_JQ" -eq 1 ]; then
          jq -r '.hooks.SessionStart? // empty | .. | .command? // empty' "$f" 2>/dev/null \
            | sed 's/^/         > /'
        fi
      fi
    fi
  done
  [ "$((HIGH_COUNT+REVIEW_COUNT))" -eq "$before" ] && \
    ok "Scanned ${#claude_files[@]} Claude config file(s) — no malicious hooks."
fi

# ---------------------------------------------------------------------------
section "2. Planted editor-persistence files"
# ---------------------------------------------------------------------------
# Exact artifacts the campaign drops into repos / node_modules.
# Only filenames that are NEVER legitimate (a real install never creates these).
# NOTE: .gemini/settings.json and .vscode/tasks.json are normal files, so they
# are checked by CONTENT below, not by mere existence.
declare -A PLANTED=(
  ["*/.claude/setup.mjs"]="Claude Code SessionStart payload"
  ["*/.claude/settings"]="Claude Code ELF backdoor binary"
  ["*/.vscode/setup.mjs"]="VS Code task-triggered payload"
  ["*/.cursor/rules/setup.mdc"]="Cursor auto-loaded rule payload"
  ["*/.github/setup.js"]="GitHub setup.js payload"
)
planted_hits=0
for pat in "${!PLANTED[@]}"; do
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    planted_hits=$((planted_hits+1))
    high "Planted file (${PLANTED[$pat]}): $hit"
  done < <(find_files -type f -path "$pat" -print)
done
# .vscode/tasks.json that auto-runs on folder open (content-based — the file
# itself is normal; only an auto-run task is suspicious).
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if grep -qE '"folderOpen"|"runOn"[[:space:]]*:[[:space:]]*"folderOpen"' "$f" 2>/dev/null; then
    planted_hits=$((planted_hits+1))
    review "VS Code task runs on folderOpen (inspect it): $f"
  fi
done < <(find_files -type f -path '*/.vscode/tasks.json' -print)
# .gemini/settings.json is a normal config file; only flag if its content
# matches a known payload signature (a planted one carries a hook/command).
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if grep -qiE "$HIGH_STR_PATTERNS" "$f" 2>/dev/null; then
    planted_hits=$((planted_hits+1))
    high "Gemini settings.json contains a payload signature: $f"
  fi
done < <(find_files -type f -path '*/.gemini/settings.json' -print)
[ "$planted_hits" -eq 0 ] && ok "No known planted editor-persistence files found."

# ---------------------------------------------------------------------------
section "3. Phantom Gyp (binding.gyp second wave)"
# ---------------------------------------------------------------------------
gyp_hits=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  # Real exfil signature is `<!(node index.js > /dev/null 2>&1 && echo stub.c)`.
  # Plain `<!(node -p ...)` is legitimate (e.g. @parcel/watcher) — do NOT flag it.
  if grep -qE 'echo[[:space:]]+stub\.c|>[[:space:]]*/dev/null[[:space:]]+2>&1[[:space:]]+&&[[:space:]]+echo' "$f" 2>/dev/null; then
    gyp_hits=$((gyp_hits+1))
    high "Weaponized binding.gyp (node-gyp exfil substitution): $f"
  elif command -v sha256sum >/dev/null 2>&1; then
    sum=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    if [ "$sum" = "$BAD_BINDING_SHA256" ]; then
      gyp_hits=$((gyp_hits+1))
      high "binding.gyp matches known-bad SHA-256: $f"
    fi
  fi
done < <(find_files -type f -name 'binding.gyp' -print)

# Oversized root-level index.js inside a package (payload is 4-4.8 MB vs ~30 KB).
while IFS= read -r f; do
  [ -z "$f" ] && continue
  gyp_hits=$((gyp_hits+1))
  sz=$(du -h "$f" 2>/dev/null | awk '{print $1}')
  review "Oversized package index.js (${sz}, expected ~30KB): $f"
done < <(find_files -type f -path '*/node_modules/*/index.js' -size +1M -print)
[ "$gyp_hits" -eq 0 ] && ok "No Phantom Gyp / oversized payload artifacts found."

# ---------------------------------------------------------------------------
section "4. Affected npm packages in lockfiles"
# ---------------------------------------------------------------------------
lock_hits=0
while IFS= read -r lf; do
  [ -z "$lf" ] && continue
  for pkg in "${BAD_PACKAGES[@]}"; do
    if grep -qF "$pkg" "$lf" 2>/dev/null; then
      lock_hits=$((lock_hits+1))
      high "Affected package '$pkg' referenced in: $lf"
    fi
  done
done < <(find_files -type f \( -name 'package-lock.json' -o -name 'yarn.lock' \
            -o -name 'pnpm-lock.yaml' -o -name 'npm-shrinkwrap.json' \) -print)
[ "$lock_hits" -eq 0 ] && ok "No affected package names found in lockfiles."
note "Note: name match alone is not proof — confirm the *version/date* against the advisories."

# ---------------------------------------------------------------------------
section "5. Known-bad file hashes"
# ---------------------------------------------------------------------------
hash_hits=0
if command -v md5sum >/dev/null 2>&1; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    sum=$(md5sum "$f" 2>/dev/null | awk '{print $1}')
    if [ "$sum" = "$BAD_ELF_MD5" ]; then
      hash_hits=$((hash_hits+1))
      high "File matches known ELF backdoor MD5: $f"
    fi
  done < <(find_files -type f -path '*/.claude/settings' -print)
fi
[ "$hash_hits" -eq 0 ] && ok "No files matched known-bad hashes."

# ---------------------------------------------------------------------------
section "6. C2 network indicators"
# ---------------------------------------------------------------------------
net_hits=0
# /etc/hosts
if [ -r /etc/hosts ]; then
  for d in "${C2_DOMAINS[@]}" "${C2_IPS[@]}"; do
    if grep -qF "$d" /etc/hosts 2>/dev/null; then
      net_hits=$((net_hits+1)); high "C2 indicator '$d' present in /etc/hosts"
    fi
  done
fi
# C2 strings inside scanned configs (cheap grep of small config files only).
while IFS= read -r f; do
  [ -z "$f" ] && continue
  for d in "${C2_DOMAINS[@]}" "${C2_IPS[@]}"; do
    if grep -qF "$d" "$f" 2>/dev/null; then
      net_hits=$((net_hits+1)); high "C2 indicator '$d' found in: $f"
    fi
  done
done < <(find_files -type f \( -path '*/.claude/*' -o -path '*/.vscode/*' \
            -o -path '*/.cursor/*' -o -path '*/.gemini/*' \) \
            ! -path '*/.claude/projects/*' ! -path '*/.claude/history/*' \
            ! -name '*.jsonl' -print)
# Live sockets to the known C2 IP.
if command -v ss >/dev/null 2>&1; then
  for ip in "${C2_IPS[@]}"; do
    if ss -tunp 2>/dev/null | grep -qF "$ip"; then
      net_hits=$((net_hits+1)); high "ACTIVE network connection to C2 IP $ip"
    fi
  done
fi
[ "$net_hits" -eq 0 ] && ok "No C2 indicators in /etc/hosts, configs, or live sockets."

# ---------------------------------------------------------------------------
section "Summary"
# ---------------------------------------------------------------------------
printf '  %sHIGH-severity hits : %d%s\n' "$C_RED" "$HIGH_COUNT" "$C_RST"
printf '  %sItems to review    : %d%s\n' "$C_YEL" "$REVIEW_COUNT" "$C_RST"

if [ "$HIGH_COUNT" -gt 0 ]; then
  cat <<EOF

${C_RED}${C_BLD}!! POSSIBLE COMPROMISE — DO NOT PANIC, AND DO NOT REVOKE TOKENS YET. !!${C_RST}
This malware retaliates against cleanup. Follow this order EXACTLY:

  1. ${C_BLD}Disconnect this machine from the network${C_RST} (Wi-Fi off / cable out).
  2. ${C_BLD}Screenshot${C_RST} the findings above as evidence.
  3. ${C_BLD}Remove the persistence by hand${C_RST}: the planted files / hooks listed,
     plus any affected node_modules. Do NOT just 'npm uninstall' — the
     backdoor lives in your editor config and survives package removal.
  4. ${C_BLD}Only then rotate every secret — FROM A DIFFERENT, TRUSTED MACHINE${C_RST}:
     npm tokens, GitHub PATs, SSH keys, then AWS/GCP/Azure, Kubernetes, Vault.
     Rotating from the infected box hands the new secrets to the attacker.
  5. Check github.com/settings/security-log for repos/workflows you did not create.
EOF
  exit 2
elif [ "$REVIEW_COUNT" -gt 0 ]; then
  printf '\n%sNo known-bad signatures, but review the [REVIEW] items above.%s\n' "$C_YEL" "$C_RST"
  printf 'A SessionStart hook or folderOpen task is only malicious if you did not add it.\n'
  exit 1
else
  printf '\n%sNo indicators of this campaign found in the scanned locations.%s\n' "$C_GRN" "$C_RST"
  printf 'This is reassuring but not a guarantee — keep --ignore-scripts hygiene up.\n'
  exit 0
fi
