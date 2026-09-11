# provisioning

Idempotent setup for servers
One `bootstrap.sh` that can **check** what's missing or **install** it, plus a
shared set of dotfiles the hosts source.

## Quick start

From your laptop:

```bash
# See what's present/missing on a host (read-only, safe):
./deploy.sh myserver --check

# Install everything missing, no prompts:
./deploy.sh myserver --yes

# Just refresh dotfiles after editing them:
./deploy.sh myserver --only dotfiles --yes
```

`deploy.sh` rsyncs this directory to `~/.server-setup` on the host, then runs
`bootstrap.sh` there. You can also copy it up and run `./bootstrap.sh` directly.

## Components

`bootstrap.sh` manages these (see `--list`):

| component | what it ensures |
|-----------|-----------------|
| `base`    | apt baseline: build-essential, cmake, git, zsh, tmux, vim, gdal-bin, ghostscript, ffmpeg, pip, ... |
| `dotfiles`| `.zshrc`, `.vimrc`, `.tmux.conf`, `.gitconfig`, `~/.config/shell/common.sh`, `~/.config/nvim/init.lua`; appends a block to `.bashrc` |
| `shell`   | login shell set to zsh |
| `spaceship`| [spaceship](https://spaceship-prompt.sh/) zsh prompt cloned to `~/.zsh/spaceship` (the zshrc falls back to `prompt adam1` if absent) |
| `datadir` | relocate big `$HOME` dirs (default `repos`) onto a data drive + symlink back (opt-in; see below) |
| `docker`  | docker engine + your user in the `docker` group |
| `rust`    | rustup (`~/.cargo`) |
| `uv`      | uv / uvx (`~/.local/bin`) |
| `pixi`    | pixi (`~/.pixi`) |
| `node`    | nvm + node LTS (`~/.nvm`) |
| `neovim`  | recent neovim + Python LSP (basedpyright, ruff) |

Each component has a `check_*` (is it there?) and an `install_*`. `--check` runs
only the checks. Installs are skipped for components that already pass, so it's
safe to re-run.

## Dotfiles layout

- `dotfiles/shell/common.sh` — aliases + functions shared by **both** zsh and bash
  (git aliases, `gplsar`/`stsar`, `shape`, `shrinkpdf`, `dls3`, `bedrock-on/off`, ...).
- `dotfiles/zshrc` — login-shell config; sources `common.sh` and any installed
  tool envs (uv, rust, pixi, nvm) guarded by existence checks.
- `dotfiles/bashrc.append` — appended to the stock `~/.bashrc` for bash parity.
- `dotfiles/vimrc` — plugin-free, fast vim for quick ssh edits.
- `dotfiles/nvim/init.lua` — modern Neovim: lazy.nvim + blink.cmp + LSP.

## Relocating big dirs to a data drive (`datadir`)

Some hosts have a small `/home` and a separate large drive (e.g. `/mnt/data`).
This moves chosen `$HOME` dirs onto it and symlinks them back, so `~/repos`
(which grows with editable installs, envs, data) lives on the big disk.

It's **opt-in** — nothing happens unless you pass `--data-root`. A plain
`--check` shows `[ -- ]` for `datadir` plus a tip listing any data drives found:

```bash
# see detected drives, then enable:
./deploy.sh HOST --check
./deploy.sh HOST --only datadir --data-root=/mnt/data          # relocates ~/repos
./deploy.sh HOST --only datadir --data-root=/mnt/data --relocate=repos,.cache
```

It creates `/<data-root>/$USER/<dir>` (with `sudo` only if the mount is
root-owned) and links `~/<dir>` to it. **It never deletes data:** a non-empty
existing dir is copied with `rsync`, then the original is renamed to
`<dir>.migrated-<timestamp>` for you to remove once you've verified. Re-running
is a no-op once the symlink is in place.

## Secrets — read this

Real secrets are **never** committed and **never** copied by `deploy.sh`.
The shared config sources `~/.config/shell/secrets.sh` last, if it exists:

```bash
cp ~/.config/shell/secrets.example.sh ~/.config/shell/secrets.sh
# then edit and add 
chmod 600 ~/.config/shell/secrets.sh
```

## Adding a component

1. Add its name to `COMPONENTS` in `bootstrap.sh`.
2. Write `desc_<name>`, `check_<name>` (return 0 when satisfied), `install_<name>`.
That's it — status, `--check`, and `--only` pick it up automatically.
