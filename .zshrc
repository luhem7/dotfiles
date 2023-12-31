# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=()

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

zstyle ':omz:update' frequency 13

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

COMPLETION_WAITING_DOTS="true"

DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    zsh-autosuggestions
    rust
    sudo
    dirhistory
    virtualenv
)

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh
source ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# User configuration

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'



# PROMPT MADNESS

[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

autoload -Uz vcs_info
precmd() {
    vcs_info
}
zstyle ':vcs_info:git:*' formats $' \uf418 %b'

display_py_env() {
    if [[ -n "$(virtualenv_prompt_info)" ]]; then
        echo " %F{yellow}\ue235 %f"
    else
        echo ""
    fi
}

setopt PROMPT_SUBST

PROMPT=\
'['\
$'%(0?.%F{green}\uf058%f .%F{red}\uf06a%f )'\
'%F{green}%D{%T}%f '\
$'%F{blue}\uf115 %4~%f'\
$'%F{red}${vcs_info_msg_0_}%f'\
$'$(display_py_env)'\
$']'


# Other env settings
alias python=python3
alias pyactivate="source .venv/bin/activate"
alias gitca="git commit --amend --reuse-message=HEAD"
alias gitfp='git push --force-with-lease'

#Inserted by nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Sourcing OS specific settings
if [[ "$(uname)" == "Linux" ]]; then
    custom_file=".zsh_linux.zsh"
elif [[ "$(uname)" == "Darwin" ]]; then
    custom_file=".zsh_macos.zsh"
else
    echo "Unsupported operating system."
    exit 1
fi

if [ -f "$custom_file" ]; then
    source "$custom_file"
fi
