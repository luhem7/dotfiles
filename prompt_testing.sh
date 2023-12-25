#! /bin/zsh

setopt PROMPT_SUBST

autoload -Uz vcs_info
precmd() { 
}

display_vcs_info() {
    vcs_info
    zstyle ':vcs_info:git:*' formats '%b '
    if [[ -n "${vcs_info_msg_0_}" ]]; then
        echo "%F{red}\uf418 ${vcs_info_msg_0_}%f"
    else
        echo ""
    fi
}

PROMPT='${NEWLINE}'\
$'%(0?.%F{green}\uf058%f .%F{red}\uf06a%f )'\
'%F{green}The current time %f'\
$'%F{blue}\uf115 %4~ %f'\
$'$(display_vcs_info)'\
$'%F{yellow}\ue235 %f'\
$'\e[3m\Uf0798 \e[0m'

unset RPROMPT