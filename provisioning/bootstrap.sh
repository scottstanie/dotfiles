#!/usr/bin/env bash
#
# bootstrap.sh -- check &/or install a standard server setup (idempotent).
#
#   ./bootstrap.sh --check                     # dry run: report present/missing
#   ./bootstrap.sh                              # install everything missing (prompts)
#   ./bootstrap.sh --yes                        # install missing, no prompts
#   ./bootstrap.sh --only base,dotfiles         # limit to some components
#   ./bootstrap.sh --only datadir --data-root=/mnt/data   # move ~/repos to a big drive + symlink
#   ./bootstrap.sh --list                       # list components
#
# Runs ON the target host. Use ../deploy.sh to push this repo to a host and run it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/dotfiles"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

CHECK_ONLY=0
ASSUME_YES=0
ONLY=""
DATA_ROOT="${DATA_ROOT:-}"      # big drive mount, e.g. /mnt/data (set via --data-root)
RELOCATE_DIRS="repos"           # $HOME-relative dirs to move onto the data drive
COMPONENTS=(base dotfiles shell spaceship datadir docker rust uv pixi node neovim)

# Ubuntu apt baseline
APT_PACKAGES="build-essential cmake git zsh tmux vim curl wget rsync jq unzip \
ca-certificates gnupg python3-pip python-is-python3 python3-venv gdal-bin ghostscript ffmpeg"

# ---------------------------------------------------------------- descriptions
desc_base()     { echo "apt baseline (compilers, git, zsh, gdal, ffmpeg, pip, ...)"; }
desc_dotfiles() { echo "shell/vim/nvim/tmux/git dotfiles -> \$HOME"; }
desc_shell()    { echo "login shell set to zsh"; }
desc_spaceship(){ echo "spaceship zsh prompt (~/.zsh/spaceship)"; }
desc_datadir()  {
  if [ -n "$DATA_ROOT" ]; then echo "relocate [$RELOCATE_DIRS] to $DATA_ROOT/\$USER + symlink";
  else echo "relocate big dirs to a data drive (pass --data-root=PATH to enable)"; fi
}
desc_docker()   { echo "docker engine + current user in docker group"; }
desc_rust()     { echo "rustup toolchain (~/.cargo)"; }
desc_uv()       { echo "uv / uvx (astral, ~/.local/bin)"; }
desc_pixi()     { echo "pixi (~/.pixi)"; }
desc_node()     { echo "nvm + node LTS (~/.nvm)"; }
desc_neovim()   { echo "recent neovim + python LSP (basedpyright, ruff)"; }

# ---------------------------------------------------------------------- checks
# Each returns 0 when satisfied. MISSING_PKGS is filled by check_base.
MISSING_PKGS=""
check_base() {
  MISSING_PKGS=""
  local p
  for p in $APT_PACKAGES; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || MISSING_PKGS="$MISSING_PKGS $p"
  done
  [ -z "$MISSING_PKGS" ]
}
check_dotfiles() { [ -f "$HOME/.config/shell/common.sh" ] && grep -q 'data-tools/provisioning' "$HOME/.zshrc" 2>/dev/null; }
check_shell()    { case "$(getent passwd "$USER" | cut -d: -f7)" in */zsh) return 0 ;; *) return 1 ;; esac; }
check_spaceship(){ [ -f "$HOME/.zsh/spaceship/spaceship.zsh" ]; }
check_datadir()  {
  [ -z "$DATA_ROOT" ] && return 0        # not requested -> nothing to do
  local base="$DATA_ROOT/$USER" d src
  for d in $RELOCATE_DIRS; do
    src="$HOME/$d"
    [ -L "$src" ] || return 1
    case "$(readlink -f "$src" 2>/dev/null)" in "$base"/*) ;; *) return 1 ;; esac
  done
  return 0
}
check_docker()   { have docker && id -nG "$USER" | tr ' ' '\n' | grep -qx docker; }
check_rust()     { [ -x "$HOME/.cargo/bin/rustc" ] || have rustc; }
check_uv()       { [ -x "$HOME/.local/bin/uv" ] || have uv; }
check_pixi()     { [ -x "$HOME/.pixi/bin/pixi" ] || have pixi; }
check_node()     { [ -s "$HOME/.nvm/nvm.sh" ] || have node; }
check_neovim()   { have nvim && have basedpyright-langserver && have ruff; }

# -------------------------------------------------------------------- installs
install_base() {
  [ -z "$SUDO" ] && [ "$(id -u)" -ne 0 ] && { err "need root/sudo for apt"; return 1; }
  $SUDO apt-get update -qq || return 1
  # shellcheck disable=SC2086
  $SUDO apt-get install -y $APT_PACKAGES
}

install_dotfiles() {
  place "$DOTFILES/zshrc"       "$HOME/.zshrc"
  place "$DOTFILES/vimrc"       "$HOME/.vimrc"
  place "$DOTFILES/tmux.conf"   "$HOME/.tmux.conf"
  place "$DOTFILES/gitconfig"   "$HOME/.gitconfig"
  place "$DOTFILES/shell/common.sh"      "$HOME/.config/shell/common.sh"
  place "$DOTFILES/secrets.example.sh"   "$HOME/.config/shell/secrets.example.sh"
  place "$DOTFILES/nvim/init.lua"        "$HOME/.config/nvim/init.lua"
  # bash parity: append our block once
  if ! grep -q 'data-tools/provisioning' "$HOME/.bashrc" 2>/dev/null; then
    printf '\n' >> "$HOME/.bashrc"
    cat "$DOTFILES/bashrc.append" >> "$HOME/.bashrc"
  fi
  info "dotfiles placed. Secrets: cp ~/.config/shell/secrets.example.sh ~/.config/shell/secrets.sh"
}

install_shell() {
  local zsh; zsh="$(command -v zsh)" || { err "zsh not installed (run 'base' first)"; return 1; }
  chsh -s "$zsh" || { err "chsh failed; run manually: chsh -s $zsh"; return 1; }
}

install_spaceship() {
  local dir="$HOME/.zsh/spaceship"
  have git || { err "git not installed (run 'base' first)"; return 1; }
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only --quiet || return 1
  else
    mkdir -p "$(dirname "$dir")"
    git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$dir" || return 1
  fi
  info "spaceship installed; ~/.zshrc picks it up on next login"
}

# create $DATA_ROOT/$USER (sudo fallback if the mount is root-owned); echoes the path
ensure_data_base() {
  local base="$DATA_ROOT/$USER"
  { [ -d "$base" ] && [ -w "$base" ]; } && { echo "$base"; return 0; }
  mkdir -p "$base" 2>/dev/null && { echo "$base"; return 0; }
  if [ -n "$SUDO" ]; then
    $SUDO mkdir -p "$base" && $SUDO chown "$USER:$(id -gn)" "$base" && { echo "$base"; return 0; }
  fi
  return 1
}

# move one $HOME dir onto the data drive and symlink it back (never deletes data)
relocate_one() {
  local d="$1" base="$2" src target bak
  src="$HOME/$d"; target="$base/$d"
  # already a symlink into the data drive?
  if [ -L "$src" ]; then
    case "$(readlink -f "$src" 2>/dev/null)" in "$base"/*) ok "$d already on $DATA_ROOT"; return 0 ;; esac
  fi
  mkdir -p "$target"
  if [ ! -e "$src" ]; then
    ln -sfn "$target" "$src"; ok "linked $src -> $target"; return 0
  fi
  if [ -L "$src" ]; then                       # wrong-target symlink -> repoint
    ln -sfn "$target" "$src"; ok "re-linked $src -> $target"; return 0
  fi
  if [ -z "$(ls -A "$src" 2>/dev/null)" ]; then # empty dir
    rmdir "$src" && ln -sfn "$target" "$src" && ok "linked (was empty) $src -> $target"; return 0
  fi
  # non-empty real dir: copy, then move the original aside as a backup, then link
  info "migrating $src -> $target via rsync (original kept as backup)"
  rsync -a "$src"/ "$target"/ || { err "rsync failed; left $src untouched"; return 1; }
  bak="${src}.migrated-$(date +%Y%m%d%H%M%S)"
  mv "$src" "$bak" && ln -sfn "$target" "$src" \
    && ok "linked $src -> $target ; backup at $bak (rm it when satisfied)"
}

install_datadir() {
  [ -z "$DATA_ROOT" ] && { info "no --data-root set; skipping (nothing to relocate)"; return 0; }
  [ -d "$DATA_ROOT" ] || { err "data root '$DATA_ROOT' not found on this host"; return 1; }
  local base; base="$(ensure_data_base)" || { err "cannot create $DATA_ROOT/$USER (permissions)"; return 1; }
  local d
  for d in $RELOCATE_DIRS; do relocate_one "$d" "$base" || return 1; done
}

install_docker() {
  if ! have docker; then
    curl -fsSL https://get.docker.com | sh || return 1
  fi
  $SUDO usermod -aG docker "$USER" || return 1
  info "added $USER to docker group -- log out/in for it to take effect"
}

install_rust() { curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; }
install_uv()   { curl -LsSf https://astral.sh/uv/install.sh | sh; }
install_pixi() { curl -fsSL https://pixi.sh/install.sh | bash; }

install_node() {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || return 1
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" && nvm install --lts
}

install_neovim() {
  # 1) recent neovim from official release tarball (same binary regardless of Ubuntu version)
  if ! have nvim; then
    local tgz url
    for name in nvim-linux-x86_64 nvim-linux64; do
      url="https://github.com/neovim/neovim/releases/latest/download/${name}.tar.gz"
      tgz="/tmp/${name}.tar.gz"
      if curl -fsSL "$url" -o "$tgz"; then
        mkdir -p "$HOME/.local"
        tar -xzf "$tgz" -C "$HOME/.local"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$HOME/.local/$name/bin/nvim" "$HOME/.local/bin/nvim"
        rm -f "$tgz"
        break
      fi
    done
    have "$HOME/.local/bin/nvim" || command -v nvim >/dev/null || { err "neovim download failed"; return 1; }
  fi
  # 2) python LSP servers (prefer uv, fall back to pip)
  if have uv; then
    uv tool install basedpyright && uv tool install ruff
  else
    python3 -m pip install --user basedpyright ruff
  fi
}

# --------------------------------------------------------------------- runner
usage() { sed -n '/^# bootstrap.sh/,/^# Runs ON/p' "$0" | sed 's/^#\s\{0,1\}//'; }

# print detected data-drive mounts as a tip (helps decide --data-root)
datadir_tip() {
  local tip
  tip="$(df -hP -x tmpfs -x overlay -x squashfs -x devtmpfs 2>/dev/null \
        | awk 'NR>1 && $6 ~ /^\/(mnt|data|scratch)/ {printf "%s (%s)  ", $6, $2}')"
  [ -n "$tip" ] && printf '         %stip%s: data drives here: %s-- enable with --data-root=/mnt/...\n' "$DIM" "$RST" "$tip"
}

status_line() {  # $1 = component
  local c="$1"
  if [ "$c" = datadir ] && [ -z "$DATA_ROOT" ]; then
    printf '  %s[ -- ]%s %-9s %s\n' "$DIM" "$RST" "$c" "$(desc_datadir)"
    datadir_tip
    return
  fi
  if "check_$c"; then
    ok "$(printf '%-9s' "$c") $("desc_$c")"
  else
    if [ "$c" = base ] && [ -n "${MISSING_PKGS# }" ]; then
      miss "$(printf '%-9s' "$c") missing:${MISSING_PKGS}"
    else
      miss "$(printf '%-9s' "$c") $("desc_$c")"
    fi
  fi
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --check|-n) CHECK_ONLY=1 ;;
      --yes|-y)   ASSUME_YES=1 ;;
      --only)        ONLY="$2"; shift ;;
      --only=*)      ONLY="${1#*=}" ;;
      --data-root)   DATA_ROOT="$2"; shift ;;
      --data-root=*) DATA_ROOT="${1#*=}" ;;
      --relocate)    RELOCATE_DIRS="$(echo "$2" | tr ',' ' ')"; shift ;;
      --relocate=*)  RELOCATE_DIRS="$(echo "${1#*=}" | tr ',' ' ')" ;;
      --list)     for c in "${COMPONENTS[@]}"; do printf '  %-9s %s\n' "$c" "$("desc_$c")"; done; exit 0 ;;
      -h|--help)  usage; exit 0 ;;
      *) err "unknown arg: $1"; usage; exit 2 ;;
    esac
    shift
  done

  local targets=("${COMPONENTS[@]}")
  if [ -n "$ONLY" ]; then
    IFS=',' read -r -a targets <<< "$ONLY"
  fi

  info "host: $(hostname)  user: $USER  os: $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
  info "status:"
  for c in "${targets[@]}"; do status_line "$c"; done

  if [ "$CHECK_ONLY" = 1 ]; then
    info "check-only mode; nothing installed."
    return 0
  fi

  local did=0
  for c in "${targets[@]}"; do
    if "check_$c"; then continue; fi
    did=1
    if confirm "$c ($("desc_$c"))"; then
      info "installing $c ..."
      if "install_$c"; then ok "$c installed"; else err "$c failed"; fi
    else
      miss "skipped $c"
    fi
  done
  [ "$did" = 0 ] && info "everything already present. Nothing to do."

  info "re-check:"
  for c in "${targets[@]}"; do status_line "$c"; done
}

main "$@"
