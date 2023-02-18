#-----------#
# Open Tmux #
#-----------#

# # if (not in tmux) and (interactive env) and (not embedded terminal)
# [[ -z $TMUX && $- == *i* && ! $(</proc/$PPID/cmdline) =~ "dolphin|vim|emacs|code" ]] && tmux

#---------------------#
# Directory Shortcuts #
#---------------------#

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME
hash -d zdot=$ZDOTDIR

hash -d Trash=~/.local/share/Trash/files
hash -d OneDrive=~/OneDrive
hash -d Downloads=~/Downloads
hash -d Workspace=~/Workspace
[[ -d ~Workspace ]] && for p in ~Workspace/*; hash -d ${p:t}=$p

#---------------------#
# P10k Instant Prompt #
#---------------------#

include -f ~cache/p10k-instant-prompt-${(%):-%n}.zsh

#---------#
# Plugins #
#---------#

[[ -d ~zdot/.zgenom ]] || git clone https://github.com/jandamm/zgenom ~zdot/.zgenom

source ~zdot/.zgenom/zgenom.zsh

zgenom autoupdate  # every 7 days

if ! zgenom saved; then
    zgenom load romkatv/powerlevel10k powerlevel10k

    zgenom ohmyzsh lib/completion.zsh
    zgenom ohmyzsh lib/clipboard.zsh

    zgenom ohmyzsh plugins/sudo
    zgenom ohmyzsh plugins/extract

    zgenom ohmyzsh --completion plugins/rust
    zgenom ohmyzsh --completion plugins/docker-compose
    zgenom load --completion spwhitt/nix-zsh-completions

    zgenom load Aloxaf/fzf-tab  # TODO: move `compinit` to the top of it?
    zgenom load chisui/zsh-nix-shell
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-autosuggestions
    zgenom load zsh-users/zsh-history-substring-search
    zgenom load marlonrichert/zsh-edit  # TODO: only keep the subword widget
    zgenom load QuarticCat/zsh-autopair

    zgenom clean
    zgenom save
    zgenom compile ~zdot
fi

#---------#
# Configs #
#---------#

# zsh misc
setopt auto_cd               # simply type dir name to cd
setopt auto_pushd            # make cd behave like pushd
setopt pushd_ignore_dups     # don't pushd duplicates
setopt pushd_minus           # exchange the meanings of `+` and `-` in pushd
setopt interactive_comments  # comments in interactive shells
setopt multios               # multiple redirections
setopt ksh_option_print      # make setopt output all options
setopt extended_glob         # extended globbing
setopt no_bare_glob_qual     # disable `PATTERN(QUALIFIERS)`, extended_glob has `PATTERN(#qQUALIFIERS)`
setopt glob_dots             # match hidden files (affect completion)
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'  # remove '/'
# autoload -U colors && colors  # provide color variables (see `which colors`)

# zsh history
setopt hist_ignore_all_dups  # no duplicates
setopt hist_save_no_dups     # don't save duplicates
setopt hist_ignore_space     # no commands starting with space
setopt hist_reduce_blanks    # remove all unneccesary spaces
setopt share_history         # share history between sessions
HISTFILE=~zdot/.zsh_history
HISTSIZE=1000000  # number of commands that are loaded into memory
SAVEHIST=1000000  # number of commands that are stored

# zsh completion
compdef _galiases -first-
_galiases() {
    if [[ $PREFIX == :* ]] {
        local des=()
        for k v in "${(@kv)galiases}"; des+=("\\:${k:1}:galias: '$v'")
        _describe 'alias' des
    }
}
zstyle ':completion:*' sort false
zstyle ':completion:*' special-dirs false  # exclude `.` and `..`

# zsh prompt
setopt transient_rprompt  # remove rprompt after accept line
PS2='%(?.%F{76}.%F{196})| %f'  # continuation prompt
RPS2='%F{8}%_%f'               # continuation right prompt

# time (zsh built-in)
TIMEFMT="\
%J   %U  user %S system %P cpu %*E total
avg shared (code):         %X KB
avg unshared (data/stack): %D KB
total (sum):               %K KB
max memory:                %M MB
page faults from disk:     %F
other page faults:         %R"

# my env variables
MY_PROXY='127.0.0.1:1089'

# fzf
export FZF_DEFAULT_OPTS='--ansi --height=60% --reverse --cycle --bind=tab:accept'

# fzf-tab
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

# fast-syntax-highlighting
unset 'FAST_HIGHLIGHT[chroma-man]'  # chroma-man will stuck history browsing

# zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND='1'

# zsh-history-substring-search
HISTORY_SUBSTRING_SEARCH_FUZZY='1'

# gpg
export GPG_TTY=$TTY

# less
export LESS='--quit-if-one-screen --RAW-CONTROL-CHARS --chop-long-lines'

# bat
export BAT_THEME='OneHalfDark'

# man-pages
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

# npm
export NPM_CONFIG_PREFIX=~/.local
export NPM_CONFIG_CACHE=~cache/npm
# export NPM_CONFIG_PROXY=$MY_PROXY

#---------#
# Aliases #
#---------#

alias l='exa -lah --group-directories-first --git --time-style=long-iso'
alias lt='l -TI .git'
alias tm='trash-put'
alias clc='clipcopy'
alias clp='clippaste'
alias clco='tee >(clipcopy)'  # clipcopy + stdout
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias edge='microsoft-edge-stable'
alias nvvp='nvvp -vm /usr/lib/jvm/java-8-openjdk/jre/bin/java'
alias sudo='sudo '
alias pc='proxychains -q '
alias env-proxy=' \
    http_proxy=$MY_PROXY \
    HTTP_PROXY=$MY_PROXY \
    https_proxy=$MY_PROXY \
    HTTPS_PROXY=$MY_PROXY '
alias cute-dot='~QuarticCat/dotfiles/cute-dot.zsh'

# Ref: https://unix.stackexchange.com/questions/70963
alias -g :n='>/dev/null'
alias -g :nn='&>/dev/null'
alias -g :bg='&>/dev/null &!'

#-----------#
# Functions #
#-----------#

f() {
    case $1 {
    doc)
        local base=~OneDrive/Documents
        local selected=$(
            fd --base-directory=$base --type=file | fzf
        )
        if [[ $selected != '' ]] {
            okular $base/$selected &>/dev/null &!
        }
        ;;
    hw)
        local base=~Homework
        local selected=$(
            fd --base-directory=$base --type=directory --max-depth=2 | fzf
        )
        if [[ $selected != '' ]] {
            dolphin $base/$selected &>/dev/null &!
        }
        ;;
    }
}

# TODO: Complete it
# rgc() {
#     rg --color=always --line-number "$@" |
#     fzf --delimiter=: \
#         --preview='bat --color=always {1} --highlight-line={2}' \
#         --preview-window='~3,+{2}+3/4'
# }

open() {
    xdg-open $@ &>/dev/null &!
}

update-all() {
    paru -Syu --noconfirm
    rustup update
    cargo install-update --all  # depends on cargo-update
}

# Ref: https://github.com/vadimcn/vscode-lldb/blob/master/MANUAL.md#debugging-externally-launched-code
code-lldb() {
    local exe="'${1:a}'"      # get real path of the executable and wrap it with quotes
    local args=("'${^@:2}'")  # wrap arguments with quotes
    code --open-url "vscode://vadimcn.vscode-lldb/launch/command?$exe $args"
}

# Ref: https://unix.stackexchange.com/questions/43196
reboot-to-windows() {
    windows_title=$(sudo rg -i windows /boot/grub/grub.cfg | cut -d "'" -f 2)
    sudo grub-reboot $windows_title && sudo reboot
}

#--------------#
# Key Bindings #
#--------------#

bindkey -r '^['  # Unbind [Esc] (default: vi-cmd-mode)

bindkey '^[[C' forward-char        # [Right]     (default: vi-forward-char)
bindkey '^[[D' backward-char       # [Left]      (default: vi-backward-char)
bindkey ' '    magic-space         # [Space]     Trigger history expansion
bindkey '^[^M' self-insert-unmeta  # [Alt-Enter] Insert newline
bindkey '^Z'   undo                # [Ctrl-Z]
bindkey '^Y'   redo                # [Ctrl-Y]
bindkey '^Q'   push-line-or-edit   # [Ctrl-Q]    Push line in single line or edit in multi line

# [Up] Combine up-line-or-beginning-search and history-substring-search-up
# Ref: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/up-line-or-beginning-search
up-line-or-substring-search() {
    typeset -g __searching
    if [[ $LBUFFER == *$'\n'* ]] {
        __searching=''
        zle up-line-or-history
    } elif [[ $PREBUFFER != '' ]] {
        zle push-line-or-edit
    } else {
        __searching=$WIDGET
        zle history-substring-search-up
    }
}
zle -N up-line-or-substring-search
bindkey '^[[A' up-line-or-substring-search

# [Down] Combine down-line-or-beginning-search and history-substring-search-down
# Ref: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/down-line-or-beginning-search
down-line-or-substring-search() {
    typeset -g __searching
    if [[ $LASTWIDGET == $__searching || $RBUFFER != *$'\n'* ]] {
        __searching=$WIDGET
        zle history-substring-search-down && return
        [[ $RBUFFER != *$'\n'* ]] && return
    }
    __searching=''
    zle down-line-or-history
}
zle -N down-line-or-substring-search
bindkey '^[[B' down-line-or-substring-search

# Trim trailing newline from pasted text
# Ref: https://unix.stackexchange.com/questions/693118
bracketed-paste() {
    zle .$WIDGET
    LBUFFER=${LBUFFER%$'\n'}
}
zle -N bracketed-paste

# Change '...' to '../..'
# Ref: https://grml.org/zsh/zsh-lovers.html#_completion
rationalize-dot() {
    if [[ $LBUFFER == *.. ]] {
        LBUFFER+='/..'
    } else {
        LBUFFER+='.'
    }
}
zle -N rationalize-dot
bindkey '.' rationalize-dot

# [Ctrl-L] Clear screen while maintaining scrollback
# Ref: https://superuser.com/questions/1389834
# FIXME: Goes wrong in tmux
clear-screen() {
    local prompt_height=$(echo -n ${(%%)PS1} | wc -l)
    local lines=$((LINES - prompt_height))
    printf "$terminfo[cud1]%.0s" {1..$lines}  # cursor down
    printf "$terminfo[cuu1]%.0s" {1..$lines}  # cursor up
    zle reset-prompt
}
zle -N clear-screen
bindkey '^L' clear-screen

# [Ctrl-R] Search history by fzf-tab
# Ref: https://github.com/Aloxaf/dotfiles/blob/0619025cb2/zsh/.config/zsh/snippets/key-bindings.zsh#L80-L102
fzf-history-search() {
    local selected=$(
        fc -rl 1 |
        ftb-tmux-popup -n '2..' --tiebreak=index --prompt='cmd> ' ${BUFFER:+-q$BUFFER}
    )
    if [[ $selected != '' ]] {
        zle vi-fetch-history -n $selected
    }
    zle reset-prompt
}
zle -N fzf-history-search
bindkey '^R' fzf-history-search

# [Ctrl-N] Navigate by xplr
# This is not a widget since properly resetting prompt is hard
# See https://github.com/romkatv/powerlevel10k/issues/72
bindkey -s '^N' '^Q cd -- ${$(xplr):-.} \n'

#---------#
# Scripts #
#---------#

include -c thefuck --alias
include -c direnv hook zsh
include -f ~zdot/p10k.zsh
# include -f /opt/intel/oneapi/setvars.sh

# Enable alternate-scroll-mode
# Ref: https://github.com/microsoft/terminal/discussions/14076
printf '\e[?1007h'
