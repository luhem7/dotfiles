#! /bin/zsh

setopt PROMPT_SUBST

PROMPT='${NEWLINE}'\
$'%(0?.%F{green}\uf058%f .%F{red}\uf06a%f )'\
'%F{green}The current time %f'\
$'%F{blue}\uf115 %4~ %f'\
$'%F{red}\uf418 git branch name %f'\
$'%F{yellow}\ue235 %f'\
$'\e[3m\Uf0798 \e[0m'
