# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "/usr/local/bin" ] ; then
    PATH="/usr/local/bin:$PATH"
fi

if [ -d "/usr/local/sbin" ] ; then
    PATH="/usr/local/sbin:$PATH"
fi

if [ -z "$SSH_AUTH_SOCK" ] ; then
	eval `ssh-agent -s`
fi
# Store 2000 commands in ~/.bash_history
HISTSIZE=2000

# set a fancy prompt (this overwrites /etc/bash.bashrc in ubuntu)
PS1='${debian_chroot:+($debian_chroot)}\u:\W\$ '

ssh-add ~/.ssh/id_rsa

# Passwords for psql
export PGPASSFILE='~/.pgpass'

# Easier to open images, files
alias xo='xdg-open'

# Shrink a pdf with compression
# usage: shrinkpdf input.pdf output.pdf
shrinkpdf() {
  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default \
  -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages \
  -dCompressFonts=true -r150 -sOutputFile=$2 $1
}

# Profile a python script
alias prof='python -m cProfile -s time'

alias subl='/usr/local/bin/sublime'

alias repo='cd ~/repos'

export ISCE_BUILD_ROOT="/home/scott/Documents/Learning/research"
export ISCE_INSTALL_ROOT="/home/scott/Documents/Learning/research"
export LIB_LOCATION_HOME="/usr"
# The directory in which ISCE will be built

# Virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export WORKON_HOME=~/envs
source ~/.local/bin/virtualenvwrapper.sh

alias js='jekyll serve'


# Git shortcuts
alias st='git status'
alias ci='git commit'
alias gpsh='git push'
alias gb='git branch'
alias gpl='git pull'
alias gk='git checkout'

alias ..='cd ..'
alias cl='clear'
alias lm='ls -laxo | more'
alias lh='ls -lh'
alias rm='rm -i'
alias fl='fleetctl'
alias fll='fleetctl list-units'
alias flj='fleetctl journal'
alias flm='fleetctl list-machines'

# Docker functions
drmall() {
	docker rmi $(docker images | grep "<none>" | awk '{print($3)}')
}

# DB connections
alias trawl='psql -h localhost -p 5432 -U scott trawler'

# pbcopy & pbpaste aliases
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'


export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'

# TexLive env variables
# http://www.tug.org/texlive/doc/texlive-en/texlive-en.html#x1-310003.4.1
export PATH=/usr/local/texlive/2017/bin/x86_64-linux:$PATH
export MANPATH=/usr/local/texlive/2017/texmf-dist/doc/man:$MANPATH
export INFOPATH=/usr/local/texlive/2017/texmf-dist/doc/info:$INFOPATH
