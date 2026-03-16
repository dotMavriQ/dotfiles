# =========================
#  Base PATH & essentials
# =========================
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"                 # Python user installs (pipx/pip --user)
export EDITOR="nano"                                  # change to nvim if you use it

# =========================
#  History (sane defaults)
# =========================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

# =========================
#  Aliases
# =========================
alias l='ls -lah'
alias ll='ls -lAh'
alias g='git'
alias ..='cd ..'
alias ...='cd ../..'

# Debian naming quirks (only if present)
command -v batcat >/dev/null && alias bat='batcat'
command -v fdfind  >/dev/null && alias fd='fdfind'

# =========================
#  Completion (zsh & SSH hosts)
# =========================
autoload -Uz compinit
compinit -d ~/.zcompdump

# Use the ssh completer for ssh/scp/sftp
autoload -Uz _ssh
compdef _ssh ssh scp sftp

# Pretty selection menu
zstyle ':completion:*' menu select

# Only show Host aliases from ~/.ssh/config (no users/known_hosts/IPs)
zstyle ':completion:*:*:(ssh|scp|sftp):*' tag-order 'hosts:-host_aliases'
zstyle -e ':completion:*:*:(ssh|scp|sftp):*:hosts' hosts 'reply=(
  ${=${${(M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#(*\?*|*\**)}
)'

# =========================
#  FZF (if available)
# =========================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

# =========================
#  Language runtimes (Go / Node / Python / PHP)
# =========================

# --- Go ---
if [ -d /usr/local/go/bin ] || [ -d "$HOME/go" ]; then
  export GOPATH="$HOME/go"
  export GOBIN="$GOPATH/bin"
  export PATH="/usr/local/go/bin:$GOBIN:$PATH"
fi

# --- Node (nvm) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# --- PHP (Composer globals) ---
if [ -d "$HOME/.config/composer/vendor/bin" ]; then
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

# =========================
#  WSL niceties
# =========================
# Clipboard helpers
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -NoProfile -Command "Get-Clipboard"'

# Open files/URLs in Windows (wslu optional)
if command -v wslview >/dev/null; then
  alias open='wslview'
else
  alias open='powershell.exe -NoProfile -Command Start-Process'
fi

# Make less & grep colorful
export LESS='-R'

# =========================
#  SSH agent & keys (WSL2: stable socket + auto-load)
# =========================
# Pin the agent socket so $SSH_AUTH_SOCK never points to a dead temp file
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# Start/repair the agent bound to that socket if it isn't usable
if ! ssh-add -l >/dev/null 2>&1; then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
fi

# Ensure your keys are loaded (no spam if already present)
if ! ssh-add -l >/dev/null 2>&1; then
  ssh-add "$HOME/.ssh/id_ed25519_work" "$HOME/.ssh/id_ed25519_personal" >/dev/null 2>&1
fi

# =========================
#  Prompt: Starship
# =========================
eval "$(starship init zsh)"

# =========================
#  Bun
# =========================
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# =========================
#  Claude Code: pre-flight repo inspection
# =========================
claude() {
  if [ ! -f ".claude/.inspected" ] && { [ -f ".claude/settings.json" ] || [ -f ".mcp.json" ]; }; then
    echo "🔍 New repo detected — running pre-flight inspection..."
    echo ""
    ~/.claude/inspect-repo.sh .
    local result=$?
    echo ""
    if [ $result -eq 2 ]; then
      read -r "reply?High-risk findings. Continue anyway? [y/N] "
      [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; return 1; }
    fi
  fi
  command claude "$@"
}
