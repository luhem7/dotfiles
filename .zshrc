# Set locale variables correctly.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor
export EDITOR='vim'

# ---------------------
# Completion System
# ---------------------
autoload -Uz compinit
compinit

# Case-insensitive and hyphen-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# Completion menu with selection
zstyle ':completion:*' menu select

# Cache completions for faster loading
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ---------------------
# Zsh Options
# ---------------------
setopt correct              # Command auto-correction
setopt PROMPT_SUBST         # Allow substitution in prompt

# ---------------------
# History
# ---------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_IGNORE_DUPS       # Don't record duplicate entries
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate when adding new
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS     # Remove unnecessary blanks
setopt HIST_VERIFY            # Show command before executing from history
setopt INC_APPEND_HISTORY     # Add commands immediately, not at shell exit

# ---------------------
# Plugins (Arch packages)
# ---------------------
# Install: sudo pacman -S zsh-syntax-highlighting zsh-autosuggestions
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---------------------
# Prompt
# ---------------------
[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

autoload -Uz vcs_info
precmd() {
    vcs_info
}
zstyle ':vcs_info:git:*' formats $' \uf418 %b'

display_py_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo " %F{yellow}\ue235 %f"
    else
        echo ""
    fi
}

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
alias gitc="git commit -m"
alias gitca="git commit --amend --reuse-message=HEAD"
alias gitfp='git push --force-with-lease'
alias gitcpc='sh ~/commit-push-changes.sh'

#Inserted by nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

# Loading up a machine specific script if it exists.
local_file="$HOME/.local_config.zsh"
if [[ -f $local_file ]]; then
    source $local_file
fi

