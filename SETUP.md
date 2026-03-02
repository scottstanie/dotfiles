# New Machine Setup

## 1. Install zsh (Linux only — macOS ships with it)

```bash
sudo apt install zsh
chsh -s $(which zsh)
# Log out and back in
```

## 2. Clone dotfiles

```bash
mkdir -p ~/repos
git clone git@github.com:scottstanie/dotfiles.git ~/repos/dotfiles
```

## 3. Install Spaceship prompt

**macOS:**
```bash
brew install spaceship
```

**Linux:**
```bash
mkdir -p ~/.zsh
git clone https://github.com/spaceship-prompt/spaceship-zsh-theme.git ~/.zsh/spaceship
```

`zshrc_common` auto-detects and sources it from either location.

## 4. Symlink your zshrc

```bash
ln -sf ~/repos/dotfiles/zshrc_mac ~/.zshrc    # any Mac
ln -sf ~/repos/dotfiles/zshrc_linux ~/.zshrc  # Linux
```

Edit the `REPOS=(...)` array in your per-machine file to match what's checked out.

## 5. SSH key

```bash
ssh-keygen -t ed25519
# Add public key to GitHub: https://github.com/settings/keys
```

## 6. Package management (pick one or both)

**Pixi:**
```bash
curl -fsSL https://pixi.sh/install.sh | bash
```

**Miniforge (conda):**
```bash
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh
bash Miniforge3-$(uname)-$(uname -m).sh
conda init zsh
```

`zshrc_mac` auto-detects whichever is installed (or both).

## 7. Common tools

**Rust:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**asdf (version manager for Node, Ruby, etc.):**
```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

**macOS:**
```bash
brew install gh jq fd ripgrep
```

**Linux:**
```bash
sudo apt install jq fd-find ripgrep
```

## 8. Other dotfiles

```bash
mkdir -p ~/.ipython/profile_default/startup
ln -sf ~/repos/dotfiles/ipython_startup.py ~/.ipython/profile_default/startup/00-startup.py
```

## Structure

```
~/.zshrc  -->  ~/repos/dotfiles/zshrc_mac (or zshrc_linux)
                       |
                       source zshrc_common   (shared: aliases, functions, env)
                       + machine-specific    (REPOS list, conda/pixi, ISCE, etc.)
```
