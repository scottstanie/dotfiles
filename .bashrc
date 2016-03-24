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

# Profile a python script
alias prof='python -m cProfile -s time'

# Update homebrew
alias morning='brew update && brew upgrade && brew doctor'

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
alias fl='fleetctl'
alias fll='fleetctl list-units'
alias flj='fleetctl journal'
alias flm='fleetctl list-machines'
export DOCKER_TLS_VERIFY=1
export DOCKER_HOST=tcp://192.168.59.103:2376
export DOCKER_CERT_PATH=~/.boot2docker/certs/boot2docker-vm

# Docker functions
drmall() {
	docker rmi $(docker images | grep "<none>" | awk '{print($3)}')
}

# DB connections
alias trawl='psql -h localhost -p 5432 -U scott trawler'

