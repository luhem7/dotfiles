#! /bin/zsh

setopt PROMPT_SUBST

PROMPT='${NEWLINE}'\
'%F{green}The current time %f'\
'%F{blue}The current path %f'\
'%F{red}git branch name %f'\
$'%F{yellow}\ue235 %f'\
$'\e[3m\Uf0798 \e[0m'
