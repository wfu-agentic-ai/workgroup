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
# What this script does:
#   1. Installs Homebrew if not present (with user confirmation)
#   2. Installs and configures git (user.name, user.email, defaultBranch)
#   3. Installs formulae: uv, node, npm, zoxide, thefuck, eza, fd,
#      bat, lazygit, ncdu, yazi, tldr
#   4. Installs casks (macOS only): ghostty
#   5. Appends shell config block to ~/.bashrc or ~/.zshrc
#      (idempotent — safe to run more than once)
#
# See: https://wfu-agentic-ai.github.io/workgroup/tutorials/cli-fundamentals.html

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

confirm() {
  local prompt="$1" response
  if $DRY_RUN; then
    dry "ask: $prompt [Y/n]"
    return 0
  fi
  printf "%s [Y/n] " "$prompt"
  read -r response
  case "${response,,}" in
    n|no) return 1 ;;
    *) return 0 ;;
  esac
}

if $DRY_RUN; then
  header "DRY RUN — no changes will be made"
fi

# ── Preflight: check for Homebrew ───────────────────────────────

if ! command -v brew &>/dev/null; then
  warn "Homebrew is not installed."
  echo ""
  echo "  Homebrew is the package manager this script uses to install"
  echo "  all the CLI tools for the workgroup."
  echo ""

  if confirm "Install Homebrew now?"; then
    if ! $DRY_RUN; then
      OS="$(uname -s)"

      # Install platform prerequisites
      if [[ "$OS" == "Darwin" ]]; then
        if ! xcode-select -p &>/dev/null; then
          info "Installing Xcode Command Line Tools (required by Homebrew)..."
          xcode-select --install
          echo ""
          warn "A dialog box may have appeared — follow the prompts to install."
          warn "After the Xcode CLT install finishes, re-run this script."
          exit 0
        fi
      else
        # Linux / WSL
        if ! dpkg -s build-essential &>/dev/null 2>&1; then
          info "Installing build-essential (required by Homebrew on Linux)..."
          sudo apt-get update -y && sudo apt-get install -y build-essential
        fi
      fi

      # Run the official Homebrew installer
      info "Running the Homebrew installer..."
      echo ""
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      # Make brew available in the current session
      if [[ "$(uname -m)" == "arm64" && -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi

      if ! command -v brew &>/dev/null; then
        fail "Homebrew installation did not complete successfully."
        echo "  Try installing manually: https://brew.sh"
        exit 1
      fi

      info "Homebrew installed successfully."
      echo ""
    fi
  else
    echo ""
    echo "  You can install Homebrew manually by following the tutorial:"
    echo "  https://wfu-agentic-ai.github.io/workgroup/tutorials/cli-fundamentals.html#installing-packages"
    echo ""
    exit 1
  fi
else
  info "Homebrew is already installed"
fi

# ── Preflight: check for Git ──────────────────────────────────

GIT_OK=false
MIN_GIT="2.5"

if command -v git &>/dev/null; then
  GIT_VER="$(git --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"
  GIT_MAJOR_MINOR="$(echo "$GIT_VER" | grep -oE '^[0-9]+\.[0-9]+')"

  # Compare version: is GIT_MAJOR_MINOR >= MIN_GIT?
  if printf '%s\n%s\n' "$MIN_GIT" "$GIT_MAJOR_MINOR" \
     | sort -V | head -1 | grep -qx "$MIN_GIT"; then
    info "git $GIT_VER is installed"
    GIT_OK=true
  else
    warn "git $GIT_VER is outdated (minimum recommended: $MIN_GIT)"
    if confirm "Upgrade git via Homebrew?"; then
      if $DRY_RUN; then
        dry "install git"
        GIT_OK=true
      else
        brew install git
        GIT_OK=true
      fi
    else
      warn "Continuing with git $GIT_VER — some features may not work."
      GIT_OK=true
    fi
  fi
else
  warn "git is not installed."
  echo ""
  echo "  Git is required for version control in the workgroup tutorials."
  echo ""

  if confirm "Install git via Homebrew?"; then
    if $DRY_RUN; then
      dry "install git"
      GIT_OK=true
    else
      info "Installing git..."
      brew install git
      GIT_OK=true
    fi
  else
    warn "Skipping git install. Version control tutorials will not work"
    warn "without git. You can install it later with: brew install git"
  fi
fi

# ── Configure Git ─────────────────────────────────────────────

if $GIT_OK && command -v git &>/dev/null; then
  header "Configuring Git"

  # user.name
  CURRENT_NAME="$(git config --global user.name 2>/dev/null || true)"
  if [[ -n "$CURRENT_NAME" ]]; then
    info "git user.name is already set to \"$CURRENT_NAME\""
  elif $DRY_RUN; then
    dry "prompt for git user.name"
  else
    echo "  Git needs your name for commit messages (e.g. 'Jane Doe')."
    printf "  Your full name: "
    read -r GIT_NAME
    if [[ -n "$GIT_NAME" ]]; then
      git config --global user.name "$GIT_NAME"
      info "git user.name set to \"$GIT_NAME\""
    else
      warn "No name entered — skipping. Set it later with:"
      warn "  git config --global user.name \"Your Name\""
    fi
  fi

  # user.email
  CURRENT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
  if [[ -n "$CURRENT_EMAIL" ]]; then
    info "git user.email is already set to \"$CURRENT_EMAIL\""
  elif $DRY_RUN; then
    dry "prompt for git user.email"
  else
    echo "  Git needs your email for commit messages."
    echo "  Use the email associated with your GitHub account."
    printf "  Your email: "
    read -r GIT_EMAIL
    if [[ -n "$GIT_EMAIL" ]]; then
      git config --global user.email "$GIT_EMAIL"
      info "git user.email set to \"$GIT_EMAIL\""
    else
      warn "No email entered — skipping. Set it later with:"
      warn "  git config --global user.email \"you@example.com\""
    fi
  fi

  # init.defaultBranch
  CURRENT_BRANCH="$(git config --global init.defaultBranch 2>/dev/null || true)"
  if [[ -n "$CURRENT_BRANCH" ]]; then
    info "git init.defaultBranch is already set to \"$CURRENT_BRANCH\""
  elif $DRY_RUN; then
    dry "set init.defaultBranch to main"
  else
    git config --global init.defaultBranch main
    info "git init.defaultBranch set to \"main\""
    echo "  (GitHub uses 'main' as the default branch name for new repos)"
  fi
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

SHELL_NAME="$(ps -o comm= -p $PPID 2>/dev/null | sed 's/^-//')"
if [[ -z "$SHELL_NAME" || ("$SHELL_NAME" != "bash" && "$SHELL_NAME" != "zsh") ]]; then
  SHELL_NAME="$(basename "$SHELL")"
fi
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
alias lat='lla --tree --level=2 --ignore-glob=.git'

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

if $GIT_OK && command -v git &>/dev/null; then
  echo ""
  echo "Git:"
  info "  version   — $(git --version)"
  GIT_SUM_NAME="$(git config --global user.name 2>/dev/null || echo '(not set)')"
  GIT_SUM_EMAIL="$(git config --global user.email 2>/dev/null || echo '(not set)')"
  info "  user      — $GIT_SUM_NAME <$GIT_SUM_EMAIL>"
  GIT_SUM_BRANCH="$(git config --global init.defaultBranch 2>/dev/null || echo '(not set)')"
  info "  default branch — $GIT_SUM_BRANCH"
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
