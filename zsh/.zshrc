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

# --- Plugins & completion (ORDER MATTERS) ---

# Completion definitions must be available before compinit
zinit light zsh-users/zsh-completions

# Initialize completion system
autoload -Uz compinit
_compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${ZSH_VERSION}"
mkdir -p "${_compdump:h}"
compinit -d "$_compdump"

# fzf-tab hooks into completion → must be AFTER compinit
zinit light Aloxaf/fzf-tab

# Other plugins can be async
# # Autosuggestions wraps widgets; keep it synchronous to avoid Tab weirdness
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

# OMZ snippets often add compdefs → replay after compinit
for _omzp in git sudo command-not-found; do
  zinit ice wait lucid
  zinit snippet "OMZP::${_omzp}"
done

# Replay any deferred compdefs
zinit cdreplay -q


setopt AUTO_LIST
# fzf-tab works best when zsh's own menu UI is disabled.
zstyle ':completion:*' menu no

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
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

# Shell integrations
if [[ -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  # source <(fzf --zsh)
fi
if [[ -t 0 && -t 1 ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
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

mosh() {
  local host="$1"
  if [ -z "$host" ]; then
    command mosh
    return
  fi
  shift
  command mosh --server=/users/nzamachn/.local/bin/mosh-server \
    "nzamachn@${host}" -- bash -il
}

# Deploy current branch to orb-dev2 by first syncing /data/obelisk-nzamachn over SSH,
# then running the Ansible playbook against that path.
deploy_orb_dev2() {
  local repo_root branch upstream_ref origin_branch force=false git_status counts ahead behind
  local remote_host="orb-dev2"
  local remote_repo="/data/obelisk-nzamachn"
  local ansible_playbook="$HOME/.venvs/ansible-2.9/bin/ansible-playbook"

  case "${1:-}" in
    --force|-f)
      force=true
      shift
      ;;
    "")
      ;;
    *)
      echo "usage: ddev2 [--force]"
      return 2
      ;;
  esac

  if (( $# > 0 )); then
    echo "usage: ddev2 [--force]"
    return 2
  fi

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "deploy_orb_dev2: run this from inside the obelisk git repo"
    return 1
  }

  [[ -f "$repo_root/ansible/deploy-playbook.yml" ]] || {
    echo "deploy_orb_dev2: ansible/deploy-playbook.yml not found under $repo_root"
    return 1
  }

  [[ -x "$ansible_playbook" ]] || {
    echo "deploy_orb_dev2: $ansible_playbook not found or not executable"
    return 1
  }

  branch="$(git -C "$repo_root" symbolic-ref --short HEAD 2>/dev/null)" || {
    echo "deploy_orb_dev2: detached HEAD; checkout a branch first"
    return 1
  }

  upstream_ref="$(git -C "$repo_root" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || {
    echo "deploy_orb_dev2: branch $branch has no upstream. Set it to origin/<remote-branch> first."
    return 1
  }

  if [[ "$upstream_ref" != origin/* ]]; then
    echo "deploy_orb_dev2: branch $branch tracks $upstream_ref, expected origin/*"
    return 1
  fi

  origin_branch="${upstream_ref#origin/}"

  if ! git -C "$repo_root" ls-remote --exit-code --heads origin "$origin_branch" >/dev/null 2>&1; then
    echo "deploy_orb_dev2: origin/$origin_branch not found. Push the branch first."
    return 1
  fi

  if [[ "$force" != true ]]; then
    git_status="$(git -C "$repo_root" status --porcelain --untracked-files=normal)"
    if [[ -n "$git_status" ]]; then
      echo "deploy_orb_dev2: worktree is not clean. Commit/stash first, or use ddev2 --force."
      return 1
    fi

    git -C "$repo_root" fetch origin "$origin_branch" --quiet || {
      echo "deploy_orb_dev2: failed to fetch origin/$origin_branch"
      return 1
    }

    counts="$(git -C "$repo_root" rev-list --left-right --count "origin/$origin_branch...HEAD" 2>/dev/null)" || {
      echo "deploy_orb_dev2: failed to compare local branch with origin/$origin_branch"
      return 1
    }

    behind="${counts%%[[:space:]]*}"
    ahead="${counts##*[[:space:]]}"

    if [[ "$ahead" != "0" ]]; then
      echo "deploy_orb_dev2: local branch is $ahead commit(s) ahead of origin/$origin_branch. Push first, or use ddev2 --force."
      return 1
    fi

    if [[ "$behind" != "0" ]]; then
      echo "deploy_orb_dev2: local branch is behind origin/$origin_branch by $behind commit(s); deploying origin state."
    fi
  fi

  ssh "$remote_host" 'bash -s' -- "$origin_branch" "$remote_repo" <<'REMOTE_SYNC' || {
set -euo pipefail
umask 022
branch="$1"
repo="$2"

cd "$repo"
git fetch origin "$branch"
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git checkout "$branch"
else
  git checkout -b "$branch" --track "origin/$branch"
fi
git pull --ff-only origin "$branch"
REMOTE_SYNC
    echo "deploy_orb_dev2: failed to sync $remote_repo on $remote_host"
    return 1
  }

  (
    cd "$repo_root/ansible" || exit 1
    "$ansible_playbook" deploy-playbook.yml -i inventory.yml \
      --extra-vars "target_host=orb-dev2"
  )
}

deploy_orb_tst() {
  local repo_root target_ref ansible_playbook="$HOME/.venvs/ansible-2.9/bin/ansible-playbook"

  case "${1:-}" in
    ""|--help|-h)
      echo "usage: dtst <branch>"
      return 2
      ;;
    -*)
      echo "usage: dtst <branch>"
      return 2
      ;;
    *)
      target_ref="$1"
      shift
      ;;
  esac

  if (( $# > 0 )); then
    echo "usage: dtst <branch>"
    return 2
  fi

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [[ -z "$repo_root" || ! -f "$repo_root/ansible/deploy-playbook.yml" ]]; then
    repo_root="$HOME/work/obelisk/obelisk"
  fi

  [[ -f "$repo_root/ansible/deploy-playbook.yml" ]] || {
    echo "deploy_orb_tst: ansible/deploy-playbook.yml not found under $repo_root"
    return 1
  }

  [[ -x "$ansible_playbook" ]] || {
    echo "deploy_orb_tst: $ansible_playbook not found or not executable"
    return 1
  }

  (
    cd "$repo_root/ansible" || exit 1
    "$ansible_playbook" -i inventory.yml deploy-playbook.yml \
      --extra-vars "target_host=orb-tst target_ref=$target_ref target_tag=false"
  )
}

alias ansible-playbook="$HOME/.venvs/ansible-2.9/bin/ansible-playbook"
alias ddev2='deploy_orb_dev2'
alias dtst='deploy_orb_tst'

 export NVM_DIR=~/.nvm
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"


# T3 Code desktop launcher
alias t3code='T3CODE_TELEMETRY_ENABLED=false "/Users/nzamachn/Downloads/T3 Code (Alpha).app/Contents/MacOS/T3 Code (Alpha)"'

# Machine-local zsh customizations. Do not commit this file.
[[ -f "$HOME/.zshrc_CUSTOM" ]] && source "$HOME/.zshrc_CUSTOM"
