#!/usr/bin/env bash
# inspect-repo.sh — Pre-flight safety check before running Claude Code
# Scans a repository for configuration that could alter Claude's behavior.
# Exit code 0 = clean, 1 = warnings found, 2 = high-risk findings.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

dir="${1:-.}"
risk=0

warn()  { echo -e "${YELLOW}⚠  $1${RESET}"; [ "$risk" -lt 1 ] && risk=1; }
danger(){ echo -e "${RED}🚨 $1${RESET}"; risk=2; }
ok()    { echo -e "${GREEN}✓  $1${RESET}"; }
header(){ echo -e "\n${BOLD}── $1${RESET}"; }

echo -e "${BOLD}Claude Code repo inspection: ${dir}${RESET}"

# ── .claude/settings.json ────────────────────────────────────────────────
header ".claude/settings.json"
settings="$dir/.claude/settings.json"
if [ -f "$settings" ]; then
  warn "Project settings file exists: $settings"

  if grep -qi 'ANTHROPIC_BASE_URL' "$settings"; then
    danger "Sets ANTHROPIC_BASE_URL — could redirect API traffic and leak your API key (CVE-2026-21852)"
  fi

  if grep -qi '"hooks"' "$settings" || grep -qi 'PreToolUse\|PostToolUse\|Stop\|SessionStart' "$settings"; then
    danger "Defines hooks — these execute shell commands in your session automatically"
  fi

  if grep -qi '"env"' "$settings"; then
    warn "Sets environment variables — review manually for anything unexpected"
  fi

  if grep -qi '"allow"' "$settings"; then
    warn "Contains 'allow' permission rules — could weaken your global deny rules' effective coverage"
  fi

  if grep -qi '"enableAllProjectMcpServers".*true' "$settings"; then
    danger "Sets enableAllProjectMcpServers: true — auto-loads all project MCP servers without prompting"
  fi

  if grep -qi 'bypass\|dangerously' "$settings"; then
    danger "References permission bypass — could disable safety prompts"
  fi

  echo -e "  ${BOLD}Contents:${RESET}"
  sed 's/^/    /' "$settings"
else
  ok "No .claude/settings.json found"
fi

# ── .mcp.json ────────────────────────────────────────────────────────────
header ".mcp.json"
mcp="$dir/.mcp.json"
if [ -f "$mcp" ]; then
  warn "Project MCP config exists: $mcp"

  urls=$(grep -oiE 'https?://[^"]+' "$mcp" 2>/dev/null || true)
  if [ -n "$urls" ]; then
    warn "MCP servers reference external URLs — verify these are trusted:"
    echo "$urls" | while read -r u; do echo -e "    $u"; done
  fi

  cmds=$(grep -oP '"command"\s*:\s*"\K[^"]+' "$mcp" 2>/dev/null || true)
  if [ -n "$cmds" ]; then
    warn "MCP servers run commands — verify these are expected:"
    echo "$cmds" | while read -r c; do echo -e "    $c"; done
  fi

  echo -e "  ${BOLD}Contents:${RESET}"
  sed 's/^/    /' "$mcp"
else
  ok "No .mcp.json found"
fi

# ── Other .claude/ files ─────────────────────────────────────────────────
header "Other .claude/ files"
if [ -d "$dir/.claude" ]; then
  others=$(find "$dir/.claude" -type f ! -name 'settings.json' 2>/dev/null || true)
  if [ -n "$others" ]; then
    warn "Additional files in .claude/:"
    echo "$others" | while read -r f; do echo -e "    $f"; done
  else
    ok "No additional .claude/ files"
  fi
else
  ok "No .claude/ directory"
fi

# ── Supply chain basics ──────────────────────────────────────────────────
header "Supply chain basics"

if [ -f "$dir/package.json" ]; then
  postinstall=$(grep -i 'postinstall\|preinstall\|install"' "$dir/package.json" 2>/dev/null || true)
  if [ -n "$postinstall" ]; then
    warn "package.json contains install hooks — review:"
    echo "$postinstall" | sed 's/^/    /'
  else
    ok "No install hooks in package.json"
  fi
else
  ok "No package.json"
fi

if [ -f "$dir/Makefile" ]; then
  warn "Makefile present — targets could execute arbitrary commands on 'make'"
fi

# ── Summary ──────────────────────────────────────────────────────────────
header "Result"
case $risk in
  0) echo -e "${GREEN}${BOLD}✓ Clean — no Claude Code config risks detected${RESET}" ;;
  1) echo -e "${YELLOW}${BOLD}⚠ Warnings — review the items above before running Claude Code${RESET}" ;;
  2) echo -e "${RED}${BOLD}🚨 High risk — do NOT run Claude Code until you understand and trust the flagged items${RESET}" ;;
esac

exit $risk
