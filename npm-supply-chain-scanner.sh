#!/usr/bin/env bash
#
# claude-code-compromise-check.sh
# -------------------------------
# Read-only detector for the June 2026 "Miasma" / TeamPCP npm supply-chain
# campaign and related Claude Code SessionStart-hook backdoors (incl. the
# "Phantom Gyp" binding.gyp second wave and the supabase/microsoft typosquats).
#
# Also covers the June 2026 "Atomic Arch" AUR supply-chain campaign: hijacked /
# orphan-adopted AUR packages whose PKGBUILD silently runs `npm install
# atomic-lockfile` / `bun install js-digest`, dropping an ELF infostealer + an
# eBPF rootkit (hides pids/files/sockets) with systemd + Tor-C2 persistence.
# Those checks look at Arch system paths (pacman log, /etc/systemd, /sys/fs/bpf)
# and run regardless of the scan roots; some need root to read fully.
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
#   Atomic Arch: SecurityWeek, StepSecurity, Cloud Security Alliance Labs, and
#   the consolidated community IOCs at github.com/lenucksi/aur-malware-check.

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

# --- Atomic Arch AUR campaign (June 2026) ----------------------------------
# Malicious npm names a hijacked PKGBUILD pulls in via `npm`/`bun install`.
# These are never a legitimate AUR build dependency. Also fed into the lockfile
# scan (section 4) so they're caught in project lockfiles too.
AUR_NPM_PACKAGES=("atomic-lockfile" "js-digest" "lockfile-js" "nextfile-js")
BAD_PACKAGES+=("${AUR_NPM_PACKAGES[@]}")

# Standalone malicious AUR package names (2025 Chaos RAT wave + fake fonts /
# "cracked" lures). Unlike the hijacked legit packages, these names are ALWAYS
# malicious, so a name match in pacman history is itself a finding.
AUR_BAD_PACKAGES=(
  "librewolf-fix-bin" "firefox-patch-bin" "zen-browser-patched-bin"
  "vesktop-bin-patched" "minecraft-cracked"
  "ttf-ms-fonts-all" "ttf-all-ms-fonts"
)

# ELF payload hashes (atomic-lockfile + js-digest infostealer, and cryptominer).
AUR_ELF_SHA256=(
  "6144d433f8a0316869877b5f834c801251bbb936e5f1577c5680878c7443c98b"
  "7883bda1ff15425f2dbe622c45a3ae105ddfa6175009bbf0b0cad9bf5c79b316"
  "47893d9badc38c54b71321263ce8178c1abb10396e0aadf9793e61ec8829e204"
)
AUR_ELF_MD5=("42b59fdbe1b72895b2951412222ebf40")

# eBPF rootkit pinned maps (hide pids/files/sockets by hooking getdents64).
AUR_BPF_MAPS=("/sys/fs/bpf/hidden_pids" "/sys/fs/bpf/hidden_names" "/sys/fs/bpf/hidden_inodes")

# Tor C2 onion used by the dropped agent.
AUR_C2_ONION="olrh4mibs62l6kkuvvjyc5lrercqg5tz543r4lsw3o6mh5qb7g7sneid.onion"

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

# read_log <file> -> stream a pacman log to stdout, transparently decompressing
# rotated/compressed variants. Missing decompressors just yield nothing.
read_log() {
  case "$1" in
    *.gz)  command -v zcat    >/dev/null 2>&1 && zcat    "$1" 2>/dev/null ;;
    *.xz)  command -v xzcat   >/dev/null 2>&1 && xzcat   "$1" 2>/dev/null ;;
    *.zst) command -v zstdcat >/dev/null 2>&1 && zstdcat "$1" 2>/dev/null ;;
    *.bz2) command -v bzcat   >/dev/null 2>&1 && bzcat   "$1" 2>/dev/null ;;
    *)     cat "$1" 2>/dev/null ;;
  esac
}

# check_aur_hash <file> -> high() if it matches an Atomic Arch ELF payload hash.
check_aur_hash() {
  local f="$1" s m h
  [ -f "$f" ] || return
  if command -v sha256sum >/dev/null 2>&1; then
    s=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    for h in "${AUR_ELF_SHA256[@]}"; do
      [ "$s" = "$h" ] && { high "File matches Atomic Arch ELF SHA-256: $f"; return; }
    done
  fi
  if command -v md5sum >/dev/null 2>&1; then
    m=$(md5sum "$f" 2>/dev/null | awk '{print $1}')
    for h in "${AUR_ELF_MD5[@]}"; do
      [ "$m" = "$h" ] && { high "File matches Atomic Arch ELF MD5: $f"; return; }
    done
  fi
}

# ---------------------------------------------------------------------------
section "Scan configuration"
# ---------------------------------------------------------------------------
note "Scan roots: ${SCAN_ROOTS[*]}"
HAS_JQ=0; command -v jq >/dev/null 2>&1 && HAS_JQ=1
[ "$HAS_JQ" -eq 1 ] && note "jq found — using structured JSON parsing for hooks." \
                    || note "jq NOT found — falling back to text matching for hooks."
[ "$(id -u)" -ne 0 ] && note "Not root — Atomic Arch system checks (/sys/fs/bpf, some units) are partial; re-run with sudo for full coverage."
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
            ! -path '*/.claude/file-history/*' \
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
section "7. Atomic Arch — malicious AUR package installs (pacman history)"
# ---------------------------------------------------------------------------
# These names are always-malicious (Chaos RAT wave / lures), so a hit in the
# pacman log or the currently-installed foreign packages is a real finding.
aur_pkg_hits=0
shopt -s nullglob
pacman_logs=( /var/log/pacman.log /var/log/pacman.log.* /var/log/pacman.log-* )
shopt -u nullglob
if [ "${#pacman_logs[@]}" -eq 0 ]; then
  note "No pacman logs found (not an Arch system, or unreadable) — skipping log check."
else
  for lg in "${pacman_logs[@]}"; do
    [ -r "$lg" ] || continue
    for pkg in "${AUR_BAD_PACKAGES[@]}"; do
      if read_log "$lg" | grep -qE "\[ALPM\] installed ${pkg} "; then
        aur_pkg_hits=$((aur_pkg_hits+1))
        high "Malicious AUR package was installed (per $(basename "$lg")): $pkg"
      fi
    done
  done
fi
# Cross-check what is installed RIGHT NOW from the AUR (foreign packages).
if command -v pacman >/dev/null 2>&1; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    for pkg in "${AUR_BAD_PACKAGES[@]}"; do
      [ "$p" = "$pkg" ] && { aur_pkg_hits=$((aur_pkg_hits+1)); high "Malicious AUR package CURRENTLY INSTALLED: $pkg"; }
    done
  done < <(pacman -Qmq 2>/dev/null)
fi
[ "$aur_pkg_hits" -eq 0 ] && ok "No known-malicious AUR package names in pacman history."

# ---------------------------------------------------------------------------
section "8. Atomic Arch — malicious npm/bun & AUR build caches"
# ---------------------------------------------------------------------------
# A hijacked PKGBUILD fetches atomic-lockfile/js-digest via npm or bun, leaving
# traces in the package-manager caches / global node_modules even if the AUR
# package was already removed.
cache_hits=0
aur_cache_dirs=()
if command -v npm >/dev/null 2>&1; then
  nc=$(npm config get cache 2>/dev/null); [ -n "$nc" ] && [ -d "$nc" ] && aur_cache_dirs+=("$nc")
  gr=$(npm root -g 2>/dev/null);          [ -n "$gr" ] && [ -d "$gr" ] && aur_cache_dirs+=("$gr")
fi
[ -d "$HOME/.npm" ] && aur_cache_dirs+=("$HOME/.npm")
[ -d "$HOME/.bun/install/cache" ] && aur_cache_dirs+=("$HOME/.bun/install/cache")
if [ "${#aur_cache_dirs[@]}" -eq 0 ]; then
  ok "No npm/bun caches found to inspect."
else
  for d in "${aur_cache_dirs[@]}"; do
    for pkg in "${AUR_NPM_PACKAGES[@]}"; do
      # By-name match (bun cache + global node_modules store packages by name).
      while IFS= read -r hit; do
        [ -z "$hit" ] && continue
        cache_hits=$((cache_hits+1))
        high "Malicious npm pkg '$pkg' present in cache (PKGBUILD pulled it): $hit"
      done < <(find "$d" -maxdepth 6 -iname "${pkg}" -o -iname "${pkg}@*" 2>/dev/null)
      # npm's content cache is hashed, but the name survives in the index metadata.
      if [ -d "$d/_cacache/index-v5" ] && grep -rqsF "\"$pkg\"" "$d/_cacache/index-v5" 2>/dev/null; then
        cache_hits=$((cache_hits+1))
        high "Malicious npm pkg '$pkg' referenced in npm cache index: $d"
      fi
    done
  done
  [ "$cache_hits" -eq 0 ] && ok "No atomic-lockfile/js-digest artifacts in npm/bun caches."
fi

# AUR helper build caches (yay/paru): the hijacked PKGBUILD / .install that pulls
# the malicious npm dep is cloned here and PERSISTS after the build — and even
# after the package is uninstalled. Highest-signal on-disk artifact. We scan it
# explicitly because ~/.cache is pruned from the general scan for speed.
# Only the malicious npm *names* / onion are flagged: legit AUR packages
# (claude-code, cline-cli, ...) run `npm install` too, so that alone is not a hit.
build_hits=0
aur_build_dirs=()
for d in "$HOME/.cache/yay" "$HOME/.cache/paru/clone" "$HOME/.cache/aurutils"; do
  [ -d "$d" ] && aur_build_dirs+=("$d")
done
if [ "${#aur_build_dirs[@]}" -eq 0 ]; then
  note "No yay/paru AUR build cache found — skipping PKGBUILD inspection."
else
  for d in "${aur_build_dirs[@]}"; do
    while IFS= read -r pf; do
      [ -z "$pf" ] && continue
      for pkg in "${AUR_NPM_PACKAGES[@]}"; do
        grep -qF "$pkg" "$pf" 2>/dev/null && \
          { build_hits=$((build_hits+1)); high "Malicious npm dep '$pkg' in AUR build file: $pf"; }
      done
      grep -qF "$AUR_C2_ONION" "$pf" 2>/dev/null && \
        { build_hits=$((build_hits+1)); high "Tor C2 onion string in AUR build file: $pf"; }
    done < <(find "$d" -maxdepth 4 -type f \
               \( -name PKGBUILD -o -name '*.install' -o -name '.SRCINFO' \) 2>/dev/null)
  done
  [ "$build_hits" -eq 0 ] && ok "No malicious deps in AUR helper build caches (yay/paru)."
fi

# ---------------------------------------------------------------------------
section "9. Atomic Arch — eBPF rootkit maps & known-bad ELF payloads"
# ---------------------------------------------------------------------------
ebpf_hits=0
for m in "${AUR_BPF_MAPS[@]}"; do
  [ -e "$m" ] && { ebpf_hits=$((ebpf_hits+1)); high "eBPF rootkit pinned map present: $m"; }
done
# Any other hidden_* pin under /sys/fs/bpf is equally suspicious.
shopt -s nullglob
for m in /sys/fs/bpf/hidden_*; do
  case " ${AUR_BPF_MAPS[*]} " in
    *" $m "*) : ;;
    *) ebpf_hits=$((ebpf_hits+1)); high "Suspicious eBPF pinned object: $m" ;;
  esac
done
shopt -u nullglob
# Hash high-risk targets: the cryptominer drop + any preinstall 'deps' hook the
# malicious npm packages ship. (Bounded — we don't hash all of /usr/bin.)
before_h=$ebpf_hits
check_aur_hash /usr/bin/monero-wallet-gui
for d in "${aur_cache_dirs[@]:-}"; do
  [ -n "${d:-}" ] && [ -d "$d" ] || continue
  while IFS= read -r ef; do check_aur_hash "$ef"; done < <(
    find "$d" -type f \( -path '*/src/hooks/deps' -o -name 'deps' \) 2>/dev/null | head -n 50
  )
done
[ "$ebpf_hits" -eq "$before_h" ] && [ "$before_h" -eq 0 ] && \
  ok "No eBPF rootkit maps or known-bad ELF payloads found."

# ---------------------------------------------------------------------------
section "10. Atomic Arch — systemd persistence & Tor C2"
# ---------------------------------------------------------------------------
sysd_hits=0
C2_RE="${AUR_C2_ONION}|monero-wallet-gui|/sys/fs/bpf/hidden_"
shopt -s nullglob
sysd_units=( /etc/systemd/system/*.service "$HOME"/.config/systemd/user/*.service )
shopt -u nullglob
for u in "${sysd_units[@]}"; do
  [ -r "$u" ] || continue
  if grep -qiE "$C2_RE" "$u" 2>/dev/null; then
    sysd_hits=$((sysd_hits+1)); high "systemd unit references an Atomic Arch IOC: $u"
    grep -niE "$C2_RE" "$u" 2>/dev/null | sed 's/^/         > /'
  # The campaign's persistence signature: always-restart, 30s backoff, running a
  # binary out of a user-writable path. Legit services run from /usr — so this
  # combination is worth an eyeball, not an automatic HIGH.
  elif grep -q 'Restart=always' "$u" 2>/dev/null && grep -q 'RestartSec=30' "$u" 2>/dev/null; then
    es=$(grep -E '^ExecStart=' "$u" 2>/dev/null | head -n1)
    case "$es" in
      *"/var/lib/"*|*"/tmp/"*|*"/home/"*|*"/.cache/"*|*"/.local/"*)
        sysd_hits=$((sysd_hits+1))
        review "systemd unit auto-restarts a binary in a writable path (verify it is yours): $u"
        printf '         > %s\n' "$es" ;;
    esac
  fi
done
# The agent's onion C2 string may also sit in the npm/bun cache payloads.
for d in "${aur_cache_dirs[@]:-}"; do
  [ -n "${d:-}" ] && [ -d "$d" ] || continue
  grep -rqsF "$AUR_C2_ONION" "$d" 2>/dev/null && \
    { sysd_hits=$((sysd_hits+1)); high "Tor C2 onion string present in cache dir: $d"; }
done
[ "$sysd_hits" -eq 0 ] && ok "No Atomic Arch systemd persistence or Tor C2 indicators found."

# ---------------------------------------------------------------------------
section "11. Neovim plugin tree (lazy.nvim) — IOC sweep"
# ---------------------------------------------------------------------------
# Neovim plugins are unsandboxed code (Lua + native build steps), so a hijacked
# plugin commit runs with your privileges. We can't audit intent, but we CAN
# sweep the installed plugin tree for this campaign's HARD indicators — the
# malicious npm deps, the Tor onion, and the npm-campaign C2 hosts — plus the
# classic `curl … | sh` dropper. Only unambiguous strings are flagged, so legit
# plugins don't trip it. ~/.local/share is scanned explicitly (it's not a roots
# default). NVIM_APPNAME users: re-run with that data dir if you use one.
nvim_lazy="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
nvim_hits=0
if [ ! -d "$nvim_lazy" ]; then
  note "No lazy.nvim plugin dir at $nvim_lazy — skipping."
else
  # Hard IOC strings (specific enough to be HIGH with negligible false positives).
  nvim_iocs=("$AUR_C2_ONION" "${AUR_NPM_PACKAGES[@]}" "${C2_DOMAINS[@]}" "${C2_IPS[@]}")
  for ioc in "${nvim_iocs[@]}"; do
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      nvim_hits=$((nvim_hits+1))
      high "Campaign IOC '$ioc' in nvim plugin file: $hit"
    done < <(grep -rIlF --exclude-dir=.git -- "$ioc" "$nvim_lazy" 2>/dev/null)
  done
  # REVIEW: remote-pipe-to-shell dropper — rare in legitimate plugin source.
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    nvim_hits=$((nvim_hits+1))
    review "Remote-pipe-to-shell pattern in nvim plugin (inspect it): $hit"
  done < <(grep -rIlE --exclude-dir=.git -- '(curl|wget)[^|]*\|[[:space:]]*(sh|bash)' "$nvim_lazy" 2>/dev/null)
  [ "$nvim_hits" -eq 0 ] && ok "No campaign IOCs or droppers in the nvim plugin tree."
fi

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
  6. ${C_BLD}If an Atomic Arch (AUR) indicator fired${C_RST}: list AUR packages with
     'pacman -Qmq', remove/downgrade the offending one, and delete the systemd
     units + eBPF maps shown above. The rootkit hooks getdents64 to HIDE itself,
     so trust nothing this box reports — confirm from a live USB before you
     believe it is clean, then rotate secrets from a different machine.
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
