# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoredups
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s checkwinsize
shopt -s globstar

#PROMPT_COMMAND='PS1="▶ [\[\e[0;97m\]\$(basename \$(dirname \"\$PWD\"))/\$(basename \"\$PWD\")\[\e[0;94m\]]\[\e[0m\]\[\e[0;33m\]\${VIRTUAL_ENV:+ (\$(basename \$VIRTUAL_ENV))}\[\e[0m\] \$ "'
pwdn() {
  pwd | awk -F/ '{if (NF >= 2) print $(NF-1) "/" $NF; else print $NF;}'
}
#PS1='▶ [\[\e[1;96m\]$(pwdn)\[\e[0m\]] \$ '
PS1='▶ [$(pwdn)] \$ '

#install zoxide
eval "$(zoxide init bash)"

#hook direnv
eval "$(direnv hook bash)"

#zoxide cd
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --cmd cd)"
fi

#zoxide zz
function zz() {
    z "$(zoxide query -l | fzf)"
}

alias ls='eza -l --icons'
alias v='nvim'
alias dc='cd'
alias c='cd'
alias :q='exit'
alias :q!='exit'
alias p='python3'
alias shit='shutdown now'
alias fb="fileBrowser >/dev/null 2>&1 & disown; exit"

#Use clip in wsl, wl-copy in linux
if grep -qEi "(microsoft|wsl)" /proc/version &> /dev/null; then
    alias y='clip.exe'
elif command -v wl-copy &> /dev/null; then
    alias y='wl-copy'
fi

export EDITOR=nvim


# opencode
export PATH=/home/julian/.opencode/bin:$PATH


export QSYS_ROOTDIR="/opt/intelquartus/quartus/sopc_builder/bin"

# Added by Quartus Prime software
export SALT_LICENSE_FILE="$SALT_LICENSE_FILE;/home/julian/.altera.quartus/questa_lic.dat"


export EZA_COLORS="\
reset:\
*.lua=38;2;0;0;0:\
di=1;38;2;0;147;147:\
ex=1;38;2;0;136;0:\
ln=38;2;0;116;177:\
or=1;38;2;139;0;0:\
fi=38;2;0;0;0:\
sn=38;2;0;0;0:\
sb=38;2;136;136;136:\
uu=38;2;0;0;0:\
gu=38;2;136;136;136:\
un=38;2;136;136;136:\
gn=38;2;136;136;136:\
ur=38;2;0;136;0:\
uw=38;2;139;0;0:\
ux=38;2;0;147;147:\
gr=38;2;0;136;0:\
gw=38;2;139;0;0:\
gx=38;2;0;147;147:\
tr=38;2;0;136;0:\
tw=38;2;139;0;0:\
tx=38;2;0;147;147:\
da=38;2;136;136;136:\
xx=38;2;176;176;176:\
hd=1;4;38;2;0;147;147:\
ga=38;2;0;136;0:\
gm=38;2;0;116;177:\
gd=38;2;139;0;0"




alias tma='tmux attach'
alias tmd='tmux detach-client'
alias tmls='tmux ls'
alias tmks='tmux kill-server'


tmux_auto() {
  [[ -n "$TMUX" ]] && return 0

  if tmux has-session 2>/dev/null; then
    tmux attach
  else
    tmux
  fi
}

bind -x '"\C-t": tmux_auto'

# Auto-start tmux: each terminal gets own session, destroyed on terminal close
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ "$TERM" != "dumb" ]] && command -v tmux &>/dev/null; then
    __ses=0; while tmux has-session -t "$__ses" 2>/dev/null; do ((__ses++)); done
    tmux new-session -d -s "$__ses"
    trap "tmux kill-session -t '$__ses' 2>/dev/null" HUP
    tmux attach -t "$__ses" && exit
fi

export PATH="$HOME/nix/scripts:$PATH"
