#!/usr/bin/env sh
set -eu

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TPM_DIR="$HOME/.tmux/plugins/tpm"
STOW_PACKAGES="zsh tmux ohmyposh"
BACKUP_DIR="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

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

  download_file "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" "$release_json"

  lazygit_version="$(sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' "$release_json" | head -n 1)"
  if [ -z "$lazygit_version" ]; then
    printf '%s\n' "Could not determine latest lazygit version."
    rm -rf "$tmp_dir"
    return 1
  fi

  download_file \
    "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${lazygit_arch}.tar.gz" \
    "$archive"
  tar xf "$archive" -C "$tmp_dir" lazygit
  run_as_root install "$tmp_dir/lazygit" -D -t /usr/local/bin/

  rm -rf "$tmp_dir"
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    return
  fi

  printf '%s\n' "lazygit not found; installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install lazygit
  elif command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    if ! run_as_root apt-get install -y lazygit; then
      printf '%s\n' "lazygit is not available from apt; installing the latest GitHub release instead..."
      install_lazygit_from_github
    fi
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y lazygit
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -S --needed --noconfirm lazygit
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper install -y lazygit
  elif command -v apk >/dev/null 2>&1; then
    run_as_root apk add lazygit
  else
    printf '%s\n' "No supported package manager found; install lazygit manually."
    exit 1
  fi
}

install_oh_my_posh() {
  if command -v oh-my-posh >/dev/null 2>&1; then
    return
  fi

  printf '%s\n' "oh-my-posh not found; installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install oh-my-posh
  else
    tmp_dir="$(mktemp -d)"
    installer="$tmp_dir/oh-my-posh-install.sh"

    download_file "https://ohmyposh.dev/install.sh" "$installer"
    sh "$installer" -d "$HOME/.local/bin"

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

if ! command -v stow >/dev/null 2>&1; then
  printf '%s\n' "stow not found; install GNU Stow before running this script."
  exit 1
fi

install_lazygit
install_oh_my_posh

for package in $STOW_PACKAGES; do
  backup_package_targets "$package"
done

stow -d "$DOTFILES_DIR" -t "$HOME" $STOW_PACKAGES

if [ -d "$TPM_DIR/.git" ]; then
  git -C "$TPM_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$TPM_DIR")"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf"
fi

if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  "$TPM_DIR/bin/install_plugins"
fi

printf '%s\n' "Install complete."
