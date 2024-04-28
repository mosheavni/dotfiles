# setopt TRANSIENT_RPROMPT

RPROMPT=''

# PROMPT='%{$FG[049]%}%(4~|.../%3~|%~)%{$reset_color%} $(branch_prompt_info) $(kube_ps1 2>/dev/null || :)'
PROMPT='%{$FG[049]%}%c%{$reset_color%} $(branch_prompt_info) $(kube_ps1 2>/dev/null || :)'
PROMPT+=$'\n'
PROMPT+='%(?:%{$fg[green]%} → :%{$fg[red]%} → )'
PROMPT+='%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[blue]%}git:(%{$fg[red]%} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%})%{%G⚡️%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})%{%G✨%}"

KUBE_PS1_CTX_COLOR=214
KUBE_PS1_NS_COLOR=44
KUBE_PS1_SYMBOL_COLOR=147
KUBE_PS1_SYMBOL_ENABLE=false
KUBE_PS1_SEPARATOR=' '
