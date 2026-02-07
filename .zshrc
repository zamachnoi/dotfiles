[[ -o interactive ]] || return
typeset -U path PATH

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" >/dev/null 2>&1
fi

# Source/Load zinit
if [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
else
  return
fi

# Add in zsh plugins
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-completions
zinit ice wait lucid
zinit light Aloxaf/fzf-tab
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

# Add in snippets
for _omzp in git sudo command-not-found; do
  zinit ice wait lucid
  zinit snippet "OMZP::${_omzp}"
done

# Load completions
autoload -Uz compinit
_compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${ZSH_VERSION}"
mkdir -p "${_compdump:h}"
if [[ -f "$_compdump" ]]; then
  compinit -C -d "$_compdump"
else
  compinit -d "$_compdump"
fi

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

# Shell integrations
if [[ -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
if [[ -t 0 && -t 1 ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
if command -v thefuck >/dev/null 2>&1; then
  fuck() {
    unset -f fuck
    eval "$(thefuck --alias)"
    fuck "$@"
  }
fi

if command -v oh-my-posh >/dev/null 2>&1; then
  _omp_config="$HOME/.config/ohmyposh/themes/custom.omp.json"
  [[ -r "$_omp_config" ]] && eval "$(oh-my-posh init zsh --config "$_omp_config")"
  unset _omp_config
fi

export NVM_DIR="$HOME/.nvm"
[[ -z "$HOMEBREW_PREFIX" && -d "/opt/homebrew" ]] && HOMEBREW_PREFIX="/opt/homebrew"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

path+=(
  "/opt/homebrew/opt/openjdk/bin"
  "/Users/nick/development/flutter/bin"
)
[[ -z "$JAVA_HOME" && -d "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home" ]] && export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
path+=("$BUN_INSTALL/bin")
export PATH

export VIRTUAL_ENV_DISABLE_PROMPT=1
export FZF_DEFAULT_COMMAND='fd --type file --hidden --exclude .git'

export EDITOR=nvim

# Ensure dotfiles managed hooks are enabled on this machine.
if command -v git >/dev/null 2>&1 && [[ -d "$HOME/dotfiles/.git" && -d "$HOME/dotfiles/.githooks" ]]; then
  git -C "$HOME/dotfiles" config core.hooksPath .githooks >/dev/null 2>&1 || true
fi
