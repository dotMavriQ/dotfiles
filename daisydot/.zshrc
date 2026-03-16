# ──────────────────────────────────────
# Path
# ──────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# ──────────────────────────────────────
# Shell options
# ──────────────────────────────────────
setopt AUTO_CD
setopt CORRECT
setopt NO_CASE_GLOB

# ──────────────────────────────────────
# History
# ──────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# ──────────────────────────────────────
# Completion
# ──────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# ──────────────────────────────────────
# Modern replacements
# ──────────────────────────────────────
# bat > cat
alias cat="bat --paging=never"
alias catp="bat"

# eza > ls
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -la"
alias la="eza --icons --group-directories-first -a"
alias lt="eza --icons --group-directories-first --tree --level=2"

# fd > find
alias find="fd"

# dust > du
alias du="dust"

# duf > df
alias df="duf"

# btop > top
alias top="btop"

# ──────────────────────────────────────
# Git
# ──────────────────────────────────────
alias gs="git status"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline --graph --decorate -20"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"
alias lg="lazygit"

# ──────────────────────────────────────
# General
# ──────────────────────────────────────
alias cls="clear"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

mkcd() { mkdir -p "$1" && cd "$1" }

music() {
  if [[ "$1" == "update" ]]; then
    rmpc update
  else
    rmpc "$@"
  fi
}

headphones() {
  local mac="E8:EE:CC:BB:1A:F7"
  local connected=$(echo -e "info $mac\nquit" | bluetoothctl 2>/dev/null | grep "Connected: yes")
  if [[ -n "$connected" ]]; then
    echo "Disconnecting soundcore Space Q45..."
    echo -e "disconnect $mac\nquit" | bluetoothctl 2>/dev/null
  else
    echo "Connecting soundcore Space Q45..."
    echo -e "power on\nconnect $mac\nquit" | bluetoothctl 2>/dev/null
  fi
}

# ──────────────────────────────────────
# Tool inits (keep at bottom)
# ──────────────────────────────────────
eval "$(starship init zsh)"
eval $(luarocks path --bin)
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
