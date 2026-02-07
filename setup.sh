#!/bin/bash
# setup.sh — WFU Agentic AI Workgroup environment setup
#
# Installs recommended Homebrew packages and configures shell
# integrations (aliases, environment variables, helper functions)
# for the workgroup CLI tutorials.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/wfu-agentic-ai/workgroup/main/setup.sh)"
#   bash setup.sh --dry-run   # preview what would happen without changing anything
#
# Requirements:
#   - Homebrew must already be installed (https://brew.sh)
#
# What this script does:
#   1. Installs formulae: uv, node, npm, zoxide, thefuck, eza, fd,
#      bat, lazygit, ncdu, yazi, tldr
#   2. Installs casks (macOS only): ghostty
#   3. Appends shell config block to ~/.bashrc or ~/.zshrc
#      (idempotent — safe to run more than once)
#
# See: https://wfu-agentic-ai.github.io/workgroup/tutorials/cli-basics.html

set -euo pipefail

# ── Parse arguments ───────────────────────────────────────────

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *)
      echo "Usage: bash setup.sh [--dry-run]"
      exit 1
      ;;
  esac
done

# ── Formatting helpers ──────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()   { printf "${GREEN}[+]${RESET} %s\n" "$*"; }
warn()   { printf "${YELLOW}[!]${RESET} %s\n" "$*"; }
fail()   { printf "${RED}[x]${RESET} %s\n" "$*"; }
header() { printf "\n${BOLD}%s${RESET}\n\n" "$*"; }
dry()    { printf "${YELLOW}[dry-run]${RESET} would %s\n" "$*"; }

if $DRY_RUN; then
  header "DRY RUN — no changes will be made"
fi

# ── Preflight: check for Homebrew ───────────────────────────────

if ! command -v brew &>/dev/null; then
  fail "Homebrew is not installed."
  echo ""
  echo "  Install Homebrew first by following the instructions in the"
  echo "  CLI fundamentals tutorial:"
  echo ""
  echo "  https://wfu-agentic-ai.github.io/workgroup/tutorials/cli-basics.html#installing-packages"
  echo ""
  exit 1
fi

# ── Install packages ────────────────────────────────────────────

FORMULAE=(uv node npm zoxide thefuck eza fd bat lazygit ncdu yazi tldr)
CASKS=(ghostty)
FAILED=()

header "Installing Homebrew formulae"

for pkg in "${FORMULAE[@]}"; do
  if brew list --formula "$pkg" &>/dev/null; then
    info "$pkg is already installed"
  elif $DRY_RUN; then
    dry "install $pkg"
  else
    info "Installing $pkg ..."
    if ! brew install "$pkg"; then
      fail "Failed to install $pkg"
      FAILED+=("$pkg")
    fi
  fi
done

# Casks are macOS-only (skip on Linux / WSL)
if [[ "$(uname -s)" == "Darwin" ]]; then
  header "Installing Homebrew casks"

  for pkg in "${CASKS[@]}"; do
    if brew list --cask "$pkg" &>/dev/null; then
      info "$pkg is already installed"
    elif $DRY_RUN; then
      dry "install --cask $pkg"
    else
      info "Installing $pkg ..."
      if ! brew install --cask "$pkg"; then
        fail "Failed to install $pkg"
        FAILED+=("$pkg")
      fi
    fi
  done
else
  warn "Skipping cask installs (casks are macOS-only)"
fi

# ── Detect shell and config file ───────────────────────────────

SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
  bash) CONFIG_FILE="$HOME/.bashrc" ;;
  zsh)  CONFIG_FILE="$HOME/.zshrc"  ;;
  *)
    warn "Unsupported shell: $SHELL_NAME"
    warn "Packages were installed, but shell config was not modified."
    warn "You can manually add integrations to your shell config file."
    exit 0
    ;;
esac

if ! $DRY_RUN; then
  touch "$CONFIG_FILE"
fi

# ── Append config block (idempotent) ───────────────────────────

MARKER_START="# >>> wfu-agentic-ai workgroup setup >>>"
MARKER_END="# <<< wfu-agentic-ai workgroup setup <<<"

if grep -qF "$MARKER_START" "$CONFIG_FILE" 2>/dev/null; then
  warn "Workgroup config block already present in $CONFIG_FILE"
  warn "To re-apply, remove the lines between the marker comments"
  warn "  ($MARKER_START ... $MARKER_END)"
  warn "and run this script again."
elif $DRY_RUN; then
  dry "back up $CONFIG_FILE"
  dry "append config block to $CONFIG_FILE with integrations for:"
  dry "  zoxide, thefuck, eza aliases, bat pager, yazi wrapper"
  dry "replace __SHELL__ placeholder with '$SHELL_NAME'"
else
  header "Configuring shell ($SHELL_NAME)"

  BACKUP="${CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
  cp "$CONFIG_FILE" "$BACKUP"
  info "Backed up $CONFIG_FILE to $BACKUP"

  cat >> "$CONFIG_FILE" << 'BLOCK'

# >>> wfu-agentic-ai workgroup setup >>>

# -- Replacements for default tools --
alias cat='bat'
alias ls='eza --icons=auto --color=auto'

# -- Command helpers --
# thefuck: command correction
eval "$(thefuck --alias)"

# -- Directory navigation and command helpers --
# zoxide: smarter cd
eval "$(zoxide init __SHELL__)"

# convenience cd aliases
alias ..='cd ..'
alias ...='cd ../..'

# clear screen alias
alias c='clear'

# fd: enhanced find (show hidden files, ignore .git)
alias fd="fd --hidden --exclude '.git'"

# ls-eza aliases (modern ls replacement)
alias la='ls --almost-all'
alias ll='ls --long --time-style=relative --ignore-glob=.git'
alias lla='la --long --time-style=relative --ignore-glob=.git'
alias lt='ls --tree --level=2 --ignore-glob=.git'
alias llt='ll --tree --level=2 --ignore-glob=.git'
alias lta='lla --tree --level=2 --ignore-glob=.git'

# yazi: browse files and cd to last visited directory on exit
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# -- Verbose commands --
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'

# Better PATH display (colon-separated to newline)
alias path='echo -e ${PATH//:/\\n}'

# bat as default pager (NOT aliased to cat)
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PAGER="bat"

# -- Git helpers --
alias lg='lazygit'
# ... (add more git aliases or functions here as needed)

# <<< wfu-agentic-ai workgroup setup <<<
BLOCK

  # Replace placeholder with the actual shell name
  sed -i.tmp "s/__SHELL__/$SHELL_NAME/" "$CONFIG_FILE"
  rm -f "${CONFIG_FILE}.tmp"

  info "Config block appended to $CONFIG_FILE"
fi

# ── Source config ───────────────────────────────────────────────

if ! $DRY_RUN; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE" 2>/dev/null || true
fi

# ── Summary ─────────────────────────────────────────────────────

if $DRY_RUN; then
  header "Dry run complete — nothing was changed"
else
  header "Setup complete"
fi

echo "Installed formulae:"
for pkg in "${FORMULAE[@]}"; do
  if [[ ${#FAILED[@]} -gt 0 ]] && printf '%s\n' "${FAILED[@]}" | grep -qx "$pkg"; then
    fail "  $pkg (failed)"
  else
    info "  $pkg"
  fi
done

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo ""
  echo "Installed casks:"
  for pkg in "${CASKS[@]}"; do
    if [[ ${#FAILED[@]} -gt 0 ]] && printf '%s\n' "${FAILED[@]}" | grep -qx "$pkg"; then
      fail "  $pkg (failed)"
    else
      info "  $pkg"
    fi
  done
fi

echo ""
echo "Shell integrations added to $CONFIG_FILE:"
info "  zoxide    — use 'z <dir>' to jump to directories you've visited"
info "  thefuck   — type 'fuck' after a mistyped command to auto-correct"
info "  eza       — 'ls' now shows icons and color; 'll' for details"
info "  bat       — man pages and pager output are syntax-highlighted"
info "  yazi      — type 'ya' to browse files (cd's on exit)"

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo ""
  warn "Some packages failed to install: ${FAILED[*]}"
  warn "Try installing them manually with: brew install <package>"
fi

echo ""
warn "Restart your terminal (or run 'source $CONFIG_FILE') to activate."
echo ""
echo "Tutorials: https://wfu-agentic-ai.github.io/workgroup/tutorials/"
echo ""
