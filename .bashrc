# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# set PATH so it includes user's private bin if it exists
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

ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/fleet_rsa

# Passwords for psql
export PGPASSFILE='~/.pgpass'

# Easier to type general opener on ubuntu
alias xo='xdg-open'

# Shrink a pdf with compression
# usage: shrinkpdf input.pdf output.pdf
shrinkpdf() {
  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default \
  -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages \
  -dCompressFonts=true -r150 -sOutputFile=$2 $1
}

# pbcopy & pbpaste aliases
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'


# Profile a python script
alias prof='python -m cProfile -s time'

alias subl='/usr/local/bin/sublime'

alias repo='cd ~/Documents/my_repositories'

# Virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python
export WORKON_HOME=~/envs
source /usr/local/bin/virtualenvwrapper.sh

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
alias rm='rm -i'


# Docker functions
drmall() {
	docker rmi $(docker images | grep "<none>" | awk '{print($3)}')
}

# DB connections
alias trawl='psql -h localhost -p 5432 -U scott trawler'

export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'


# TexLive env variables
# http://www.tug.org/texlive/doc/texlive-en/texlive-en.html#x1-310003.4.1
export PATH=/usr/local/texlive/2017/bin/x86_64-linux:$PATH
export MANPATH=/usr/local/texlive/2017/texmf-dist/doc/man:$MANPATH
export INFOPATH=/usr/local/texlive/2017/texmf-dist/doc/info:$INFOPATH
