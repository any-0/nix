# Completion
autoload -Uz compinit
_ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "${_ZSH_CACHE_DIR}"
compinit -d "${_ZSH_CACHE_DIR}/zcompdump-${ZSH_VERSION}"

setopt extendedglob globdots MENU_COMPLETE
zstyle ':completion:*' matcher-list 'r:|.=*' 'r:|.=* l:|=.'

# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"
mkdir -p "${HISTFILE:h}"
setopt HIST_IGNORE_DUPS APPEND_HISTORY SHARE_HISTORY

# Prompt
source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/prompt.zsh"

# Zsh vi mode (line editor, not the vim app)
bindkey -v
export KEYTIMEOUT=10

_zsh_set_cursor() {
    local tty_device="${TTY:-/dev/tty}"
    if [[ "${KEYMAP}" == vicmd ]]; then
        printf '\e[2 q' > "${tty_device}"  # steady block
    else
        printf '\e[6 q' > "${tty_device}"  # steady bar
    fi
}

zle-keymap-select() { _zsh_set_cursor; }
zle -N zle-keymap-select

zle-line-init() {
    zle -K viins
    _zsh_set_cursor
}
zle -N zle-line-init

zle-line-finish() {
    local tty_device="${TTY:-/dev/tty}"
    printf '\e[6 q' > "${tty_device}"
}
zle -N zle-line-finish

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# zoxide fzf picker
function zz() {
    z "$(zoxide query -l | fzf)"
}

# Aliases
alias ls='eza -l --icons'
alias v='nvim'
alias dc='cd'
alias c='cd'
alias :q='exit'
alias :q!='exit'
alias p='python3'
alias python='python3'
alias shit='shutdown now'
alias fb="fileBrowser >/dev/null 2>&1 & disown; exit"

alias tma='tmux attach'
alias tmd='tmux detach-client'
alias tmls='tmux ls'
alias tmks='tmux kill-server'

# Clipboard (WSL vs Linux)
if grep -qEi "(microsoft|wsl)" /proc/version &> /dev/null; then
    alias y='clip.exe'
elif command -v wl-copy &> /dev/null; then
    alias y='wl-copy'
fi

# Environment
export EDITOR=nvim
export PATH=/home/julian/.opencode/bin:$PATH
export PATH="$HOME/nix/scripts:$PATH"
export QSYS_ROOTDIR="/opt/intelquartus/quartus/sopc_builder/bin"
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

# Tmux
tmux_auto() {
    [[ -n "$TMUX" ]] && return 0
    if tmux has-session 2>/dev/null; then
        tmux attach
    else
        tmux
    fi
}

# Ctrl-T for tmux (zsh widget)
zle -N tmux_auto_widget
tmux_auto_widget() { tmux_auto }
bindkey '^T' tmux_auto_widget

# Word-jump navigation (Ctrl + Left/Right)
for km in emacs viins; do
    bindkey -M "$km" '^[[1;5D' backward-word
    bindkey -M "$km" '^[[1;5C' forward-word
    bindkey -M "$km" '^[[5D' backward-word
    bindkey -M "$km" '^[[5C' forward-word
done

# Auto-start tmux
if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ "$TERM" != "dumb" ]] && command -v tmux &>/dev/null; then
    __ses=0; while tmux has-session -t "$__ses" 2>/dev/null; do ((__ses++)); done
    tmux new-session -d -s "$__ses"
    trap "tmux kill-session -t '$__ses' 2>/dev/null" HUP
    tmux attach -t "$__ses" && exit
fi
