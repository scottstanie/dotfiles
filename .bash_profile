# .bash_profile

# include .bashrc if it exists
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi


export CLICOLOR=1

export LSCOLORS=GxFxCxDxBxegedabagaced


test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

##
# Your previous /Users/scott/.bash_profile file was backed up as /Users/scott/.bash_profile.macports-saved_2019-04-02_at_18:23:30
##


# MacPorts Installer addition on 2019-04-02_at_18:23:30: adding an appropriate PATH variable for use with MacPorts.
# export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.


# MacPorts Installer addition on 2019-04-02_at_18:23:30: adding an appropriate MANPATH variable for use with MacPorts.
# export MANPATH="/opt/local/share/man:$MANPATH"
# Finished adapting your MANPATH environment variable for use with MacPorts.


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/scott/opt/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/scott/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/scott/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/scott/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

conda activate mapping


export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$HOME/.gem/ruby/2.7.0/bin:$PATH"

export BASH_SILENCE_DEPRECATION_WARNING=1
