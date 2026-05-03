#!/usr/bin/env sh
set -eu

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TPM_DIR="$HOME/.tmux/plugins/tpm"
STOW_PACKAGES="zsh tmux ohmyposh nvim"
BACKUP_DIR="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
SYSTEM_TOOLS="git tmux fzf fd rg zoxide stow curl tar unzip zig python3 tree-sitter"

PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    printf '%s\n' "sudo not found; run this script as root or install the missing tool manually."
    return 1
  fi
}

download_file() {
  url="$1"
  output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$output" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$output" "$url"
  else
    printf '%s\n' "curl or wget is required to download missing tools."
    return 1
  fi
}

warn_install_failed() {
  name="$1"

  printf 'Warning: could not install %s; continuing.\n' "$name"
}

install_lazygit_from_github() {
  case "$(uname -m)" in
    x86_64 | amd64) lazygit_arch="x86_64" ;;
    aarch64 | arm64) lazygit_arch="arm64" ;;
    armv6l | armv7l) lazygit_arch="armv6" ;;
    i386 | i686) lazygit_arch="32-bit" ;;
    *)
      printf 'Unsupported architecture for lazygit release: %s\n' "$(uname -m)"
      return 1
      ;;
  esac

  tmp_dir="$(mktemp -d)"
  release_json="$tmp_dir/release.json"
  archive="$tmp_dir/lazygit.tar.gz"

  if ! download_file "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" "$release_json"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  lazygit_version="$(sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' "$release_json" | head -n 1)"
  if [ -z "$lazygit_version" ]; then
    printf '%s\n' "Could not determine latest lazygit version."
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! download_file \
    "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${lazygit_arch}.tar.gz" \
    "$archive"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! tar xf "$archive" -C "$tmp_dir" lazygit; then
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! run_as_root install "$tmp_dir/lazygit" -D -t /usr/local/bin/; then
    rm -rf "$tmp_dir"
    return 1
  fi

  rm -rf "$tmp_dir"
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    return
  fi

  printf '%s\n' "lazygit not found; installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install lazygit || return 1
  elif command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    if ! run_as_root apt-get install -y lazygit; then
      printf '%s\n' "lazygit is not available from apt; installing the latest GitHub release instead..."
      install_lazygit_from_github
    fi
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y lazygit || return 1
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -S --needed --noconfirm lazygit || return 1
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper install -y lazygit || return 1
  elif command -v apk >/dev/null 2>&1; then
    run_as_root apk add lazygit || return 1
  else
    printf '%s\n' "No supported package manager found; install lazygit manually."
    return 1
  fi
}

install_neovim_linux() {
  if [ "$(uname -s)" != "Linux" ]; then
    return
  fi

  case "$(uname -m)" in
    x86_64 | amd64) ;;
    *)
      printf 'Unsupported architecture for Neovim tarball: %s\n' "$(uname -m)"
      return 1
      ;;
  esac

  printf '%s\n' "Installing Neovim latest release..."

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/nvim-linux-x86_64.tar.gz"

  if ! download_file \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
    "$archive"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! run_as_root rm -rf /opt/nvim-linux-x86_64; then
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! run_as_root tar -C /opt -xzf "$archive"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  rm -rf "$tmp_dir"
}

install_system_packages() {
  if command -v brew >/dev/null 2>&1; then
    brew install "$@"
  elif command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -S --needed --noconfirm "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper install -y "$@"
  elif command -v apk >/dev/null 2>&1; then
    run_as_root apk add "$@"
  else
    printf '%s\n' "No supported package manager found; install the missing packages manually."
    return 1
  fi
}

install_system_package() {
  install_system_packages "$1"
}

package_for_tool() {
  tool="$1"

  case "$tool" in
    fd)
      if command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' "fd-find"
      else
        printf '%s\n' "fd"
      fi
      ;;
    rg)
      printf '%s\n' "ripgrep"
      ;;
    python3)
      if command -v pacman >/dev/null 2>&1; then
        printf '%s\n' "python"
      else
        printf '%s\n' "python3"
      fi
      ;;
    tree-sitter)
      if command -v brew >/dev/null 2>&1 || command -v zypper >/dev/null 2>&1; then
        printf '%s\n' "tree-sitter"
      else
        printf '%s\n' "tree-sitter-cli"
      fi
      ;;
    *)
      printf '%s\n' "$tool"
      ;;
  esac
}

install_system_tool() {
  tool="$1"

  if command -v "$tool" >/dev/null 2>&1; then
    return
  fi

  package="$(package_for_tool "$tool")"
  printf '%s\n' "$tool not found; installing $package..."
  if ! install_system_package "$package"; then
    warn_install_failed "$package"
    return 1
  fi

  if [ "$tool" = "fd" ] && ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi

  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Warning: %s is still unavailable after installing %s.\n' "$tool" "$package"
    return 1
  fi
}

install_system_tools() {
  missing_tools=""

  for tool in $SYSTEM_TOOLS; do
    if ! install_system_tool "$tool"; then
      missing_tools="$missing_tools $tool"
    fi
  done

  if [ -n "$missing_tools" ]; then
    printf 'Warning: some tools are still missing:%s\n' "$missing_tools"
  fi
}

install_python_venv_support() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "Warning: python3 is unavailable; Mason Python packages may fail to install."
    return
  fi

  tmp_dir="$(mktemp -d)"

  if python3 -m venv "$tmp_dir/venv" >/dev/null 2>&1; then
    rm -rf "$tmp_dir"
    return
  fi

  rm -rf "$tmp_dir"
  printf '%s\n' "python3 venv support not found; installing..."

  if command -v brew >/dev/null 2>&1; then
    venv_packages="python"
  elif command -v apt-get >/dev/null 2>&1; then
    venv_packages="python3-venv"
  elif command -v dnf >/dev/null 2>&1; then
    venv_packages="python3"
  elif command -v pacman >/dev/null 2>&1; then
    venv_packages="python"
  elif command -v zypper >/dev/null 2>&1; then
    venv_packages="python3"
  elif command -v apk >/dev/null 2>&1; then
    venv_packages="python3 py3-pip"
  else
    printf '%s\n' "No supported package manager found; install Python venv support manually."
    return 1
  fi

  if ! install_system_packages $venv_packages; then
    warn_install_failed "$venv_packages"
    return 1
  fi

  tmp_dir="$(mktemp -d)"
  if ! python3 -m venv "$tmp_dir/venv" >/dev/null 2>&1; then
    rm -rf "$tmp_dir"
    printf '%s\n' "Warning: python3 venv support is still unavailable after installation."
    return 1
  fi

  rm -rf "$tmp_dir"
}

install_oh_my_posh() {
  if command -v oh-my-posh >/dev/null 2>&1; then
    return
  fi

  printf '%s\n' "oh-my-posh not found; installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install oh-my-posh || return 1
  else
    tmp_dir="$(mktemp -d)"
    installer="$tmp_dir/oh-my-posh-install.sh"

    if ! download_file "https://ohmyposh.dev/install.sh" "$installer"; then
      rm -rf "$tmp_dir"
      return 1
    fi

    if ! bash "$installer" -d "$HOME/.local/bin"; then
      rm -rf "$tmp_dir"
      return 1
    fi

    rm -rf "$tmp_dir"
  fi
}

backup_package_targets() {
  package="$1"

  find "$DOTFILES_DIR/$package" -type f | while IFS= read -r source_path; do
    rel_path="${source_path#"$DOTFILES_DIR/$package/"}"
    target_path="$HOME/$rel_path"

    if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
      continue
    fi

    source_real="$(readlink -f "$source_path")"
    target_real="$(readlink -f "$target_path" 2>/dev/null || true)"

    if [ "$source_real" = "$target_real" ]; then
      continue
    fi

    backup_path="$BACKUP_DIR/$rel_path"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target_path" "$backup_path"
    printf 'Backed up %s to %s\n' "$target_path" "$backup_path"
  done
}

install_system_tools
install_python_venv_support || warn_install_failed "Python venv support"
install_lazygit || warn_install_failed "lazygit"
install_oh_my_posh || warn_install_failed "oh-my-posh"
install_neovim_linux || warn_install_failed "Neovim"

if ! command -v stow >/dev/null 2>&1; then
  printf '%s\n' "stow not found; install GNU Stow before running this script."
  exit 1
fi

for package in $STOW_PACKAGES; do
  backup_package_targets "$package"
done

stow -d "$DOTFILES_DIR" -t "$HOME" $STOW_PACKAGES

if [ -d "$TPM_DIR/.git" ]; then
  git -C "$TPM_DIR" pull --ff-only || warn_install_failed "tmux plugin manager update"
else
  mkdir -p "$(dirname "$TPM_DIR")"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" || warn_install_failed "tmux plugin manager"
fi

if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf"
fi

if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  "$TPM_DIR/bin/install_plugins" || warn_install_failed "tmux plugins"
fi

printf '%s\n' "Install complete."
