# ~/.config/shell/common.sh
# Shared aliases + functions, sourced by BOTH zsh (.zshrc) and bash (.bashrc).
# Managed by data-tools/provisioning -- edit here, then re-deploy.
# Host-specific / secret values live in ~/.config/shell/secrets.sh (untracked).

# --- Directories ---
export REPODIR="${HOME}/repos"
alias repo="cd ${REPODIR}"
alias learn='cd ~/Documents/Learning'

# --- Editor ---
export EDITOR="${EDITOR:-vim}"
alias vi='vim -u NONE'

# --- Git ---
alias st='git status'
alias ci='git commit'
alias ga='git add'
alias gd='git diff'
alias gb='git branch'
alias gpl='git pull'
alias gpsh='git push'
alias gk='git checkout'
alias gw='git worktree'

# --- ls / navigation ---
alias ..='cd ..'
alias cl='clear'
alias lsm='ls -laxo | more'
alias lsh='ls -lh'
alias lss='ls -lhS'
alias lst='ls -lht'
lsth() { lst "$1" | head; }
alias rm='rm -i'

# --- Python debugging ---
alias prof='python -m cProfile -s time'
alias pdb='python -m ipdb -c continue'

# --- Numerical / IO env (sane server defaults) ---
export HDF5_USE_FILE_LOCKING=FALSE   # MintPy/h5py on shared filesystems
export MPLBACKEND=agg                # headless matplotlib; speeds up import
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=1

# --- SAR repo helpers (operate over the repos under $REPODIR) ---
REPOS="dolphin opera-utils sweets sardem snaphu-py whirlwind-insar sentineleof COMPASS"
gplsar()  { for D in $REPOS; do [ -d "$REPODIR/$D" ] && ( cd "$REPODIR/$D" && echo "== $D ==" && git pull ); done; }
stsar()   { for D in $REPOS; do [ -d "$REPODIR/$D" ] && ( cd "$REPODIR/$D" && echo "== $D ==" && git status ); done; }
gpshsar() { for D in $REPOS; do [ -d "$REPODIR/$D" ] && ( cd "$REPODIR/$D" && git push ); done; }
pipsar()  { for D in $REPOS; do [ -d "$REPODIR/$D" ] && ( cd "$REPODIR/$D" && pip install --no-deps -e . ); done; }

lsimports() { git grep import | cut -d':' -f2 | sed -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' | sort | uniq; }

# --- ISCE stack processors (add to PATH on demand) ---
isce_add_strip() { PATH="$PATH:${REPODIR}/isce2/contrib/stack/stripmapStack"; export PATH; }
isce_add_tops()  { PATH="$PATH:${REPODIR}/isce2/contrib/stack/topsStack"; export PATH; }

# --- PDF / media / raster helpers ---
shrinkpdf() {
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default \
       -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages \
       -dCompressFonts=true -r150 -sOutputFile="$2" "$1"
}
mov2gif() {
    output="${2:-screen.gif}"
    ffmpeg -i "$1" -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$output"
}
export SHRINKOPTS=" -co nbits=16 -co compress=deflate -co predictor=2 -co tiled=yes "
compresstif() { gdal_translate "$1" /tmp/tmptif.tif -co compress=deflate -co predictor=2 -co tiled=yes && mv /tmp/tmptif.tif "$1"; }
shape() {
    for f in "$@"; do
        echo "$f"
        DISPLAY='' rio info "$f" | jq -c .count,.shape | tr -d '[]'
    done
}
demheight() {
    VRT="/vsicurl/https://raw.githubusercontent.com/scottstanie/sardem/master/sardem/data/cop_global.vrt"
    gdallocationinfo -wgs84 -valonly "$VRT" "$1" "$2"
}

# --- Capella tooling ---
alias cr='capella-reader'

# download a presigned S3 URL, naming the file after the key (query string stripped);
# resumes a partial file of the same name. usage: dls3 'https://...&X-Amz-Signature=...'
dls3() { curl -fL --retry 3 -C - -o "$(basename "${1%%\?*}")" "$1"; }

# --- pixi env helper ---
pixi-shell() { local cur; cur="$(pwd)"; cd "$HOME/repos/pixi-envs/$1" && pixi shell; cd "$cur"; }
alias pixi-map='pixi-shell mapping-313'

# --- Claude Code / Bedrock helpers (NOT FOR ITAR CODE) ---
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="${AWS_REGION:-us-west-2}"
bedrock-on() {
  export ANTHROPIC_BEDROCK_BASE_URL="https://bedrock-runtime-fips.us-gov-west-1.amazonaws.com"
  export AWS_ENDPOINT_URL_BEDROCK="https://bedrock-fips.us-gov-west-1.amazonaws.com"
  export AWS_ENDPOINT_URL_BEDROCK_RUNTIME="https://bedrock-runtime-fips.us-gov-west-1.amazonaws.com"
  export AWS_REGION="us-gov-west-1" AWS_DEFAULT_REGION="us-gov-west-1" AWS_PROFILE="gov-bedrock"
  export CLAUDE_CODE_USE_BEDROCK=1
  export ANTHROPIC_DEFAULT_SONNET_MODEL="us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="us-gov.anthropic.claude-opus-4-8"
  export ANTHROPIC_MODEL="us-gov.anthropic.claude-opus-4-8"
  echo "Bedrock env ON"
}
bedrock-off() {
  unset ANTHROPIC_BEDROCK_BASE_URL AWS_ENDPOINT_URL_BEDROCK AWS_ENDPOINT_URL_BEDROCK_RUNTIME \
        AWS_REGION AWS_DEFAULT_REGION AWS_PROFILE CLAUDE_CODE_USE_BEDROCK \
        ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_MODEL
  echo "Bedrock env OFF"
}
