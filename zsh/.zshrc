#===========#
# Open Tmux #
#===========#

# # if (not in tmux) and (interactive env) and (not embedded terminal)
# [[ -z $TMUX && $- == *i* && ! $(</proc/$PPID/cmdline) =~ "dolphin|vim|emacs|code" ]] && tmux

#=====================#
# Directory Shortcuts #
#=====================#

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME
hash -d zdot=$ZDOTDIR

hash -d Trash=~/.local/share/Trash/files
hash -d OneDrive=~/OneDrive
hash -d Downloads=~/Downloads
hash -d Workspace=~/Workspace
for p in ~Workspace/*(N); hash -d ${p:t}=$p

#=====================#
# P10k Instant Prompt #
#=====================#

include -f ~cache/p10k-instant-prompt-${(%):-%n}.zsh

#==================#
# Plugins (Part I) #
#==================#

[[ -d ~zdot/.zcomet ]] ||
git clone https://github.com/agkozak/zcomet ~zdot/.zcomet/bin

source ~zdot/.zcomet/bin/zcomet.zsh

zcomet load ohmyzsh lib {completion,clipboard}.zsh

zcomet fpath ohmyzsh plugins/rust
zcomet fpath ohmyzsh plugins/docker-compose
zcomet fpath spwhitt/nix-zsh-completions
zcomet fpath zsh-users/zsh-completions src
zcomet load tj/git-extras etc git-extras-completion.zsh

zcomet load chisui/zsh-nix-shell

zcomet load zsh-users/zsh-history-substring-search
HISTORY_SUBSTRING_SEARCH_FUZZY=true

zcomet load hlissner/zsh-autopair
AUTOPAIR_BKSPC_WIDGET='backward-delete-char'

#=============#
# Completions #
#=============#

# general
zstyle ':completion:*' sort false
zstyle ':completion:*' special-dirs false  # exclude `.` and `..` (enabled by OMZL::completion.zsh)

# docker
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# galiases
compdef _galiases -first-
_galiases() {
    if [[ $PREFIX == :* ]] {
        local des=()
        for k v in "${(@kv)galiases}"; des+=("\\:${k:1}:galias: '$v'")
        _describe 'alias' des
    }
}

#===========#
# Functions #
#===========#

open() {
    xdg-open $@ &>/dev/null &!
}

f() {
    case $1 {
    doc)
        local base=~OneDrive/Documents
        local result=$(fd --base-directory=$base --type=file | fzf)
        [[ $result != '' ]] && open $base/$result
        ;;
    hw)
        local base=~Homework
        local result=$(fd --base-directory=$base --type=directory --max-depth=2 | fzf)
        [[ $result != '' ]] && open $base/$result
        ;;
    }
}

# Ref: https://github.com/vadimcn/vscode-lldb/blob/master/MANUAL.md#debugging-externally-launched-code
code-lldb() {
    local exe="'${1:a}'"      # get real path of the executable and wrap it with quotes
    local args=("'${^@:2}'")  # wrap arguments with quotes
    code --open-url "vscode://vadimcn.vscode-lldb/launch/command?$exe $args"
}

#==============#
# Key Bindings #
#==============#

bindkey -r '^['  # Unbind [Esc]    (default: vi-cmd-mode)

bindkey '^[[D' backward-char       # [Left]      (default: vi-backward-char)
bindkey '^[[C' forward-char        # [Right]     (default: vi-forward-char)
bindkey '^A'   beginning-of-line   # [Ctrl-A]
bindkey '^E'   end-of-line         # [Ctrl-E]
bindkey '^Z'   undo                # [Ctrl-Z]
bindkey '^Y'   redo                # [Ctrl-Y]
bindkey ' '    magic-space         # [Space]     Trigger history expansion
bindkey '^[^M' self-insert-unmeta  # [Alt-Enter] Insert newline
bindkey '^Q'   push-line-or-edit   # [Ctrl-Q]    Push line in single-line or edit in multi-line

# Ref: https://github.com/marlonrichert/zsh-edit
qc-word-widgets() {
    local -i move=0
    if [[ $WIDGET == *-shellword ]] {
        local words=(${(Z:n:)BUFFER}) lwords=(${(Z:n:)LBUFFER})
        if [[ $WIDGET == *-backward-* ]] {
            local tail=$lwords[-1]
            move=-${(M)#LBUFFER%$tail*}
        } else {
            local head=${${words[$#lwords]#$lwords[-1]}:-$words[$#lwords+1]}
            move=+${(M)#RBUFFER#*$head}
        }
    } else {
        local subword='([[:WORD:]]##~*[^[:upper:]]*[[:upper:]]*~*[[:alnum:]]*[^[:alnum:]]*)'
        local word="(${subword}|[^[:WORD:][:space:]]##|[[:space:]]##)"
        if [[ $WIDGET == *-backward-* ]] {
            move=-${(M)#LBUFFER%%${~word}(?|)}
        } else {
            move=+${(M)#RBUFFER##(?|)${~word}}
        }
    }
    if [[ $WIDGET == *-kill-* ]] {
        (( MARK = CURSOR + move ))
        zle .kill-region
        zle -f kill
    } else {
        (( CURSOR += move ))
    }
}
for w in qc-{back,for}ward-{,kill-}{sub,shell}word; zle -N $w qc-word-widgets
bindkey '^[[1;5D' qc-backward-subword         # [Ctrl-Left]
bindkey '^[[1;5C' qc-forward-subword          # [Ctrl-Right]
bindkey '^[[1;3D' qc-backward-shellword       # [Alt-Left]
bindkey '^[[1;3C' qc-forward-shellword        # [Alt-Right]
bindkey '^H'      qc-backward-kill-subword    # [Ctrl-Backspace]
bindkey '^W'      qc-backward-kill-subword    # [Ctrl-Backspace] (in VSCode)
bindkey '^[[3;5~' qc-forward-kill-subword     # [Ctrl-Delete]
bindkey '^[^?'    qc-backward-kill-shellword  # [Alt-Backspace]
bindkey '^[[3;3~' qc-forward-kill-shellword   # [Alt-Delete]

# [Up] Combine up-line-or-beginning-search and history-substring-search-up
qc-up-line-or-search() {
    if [[ $LBUFFER == *$'\n'* ]] {
        zle .up-line
    } else {
        zle history-substring-search-up
    }
}
zle -N qc-up-line-or-search
bindkey '^[[A' qc-up-line-or-search

# [Down] Combine down-line-or-beginning-search and history-substring-search-down
qc-down-line-or-search() {
    if [[ $RBUFFER == *$'\n'* ]] {
        zle .down-line
    } else {
        zle history-substring-search-down
    }
}
zle -N qc-down-line-or-search
bindkey '^[[B' qc-down-line-or-search

# [Enter] Insert `\n` when accept-line would result in a parse error or PS2.
# Ref: https://github.com/romkatv/zsh4humans/blob/v5/fn/z4h-accept-line
qc-accept-line() {
    if [[ $(functions[-qc-test]=$BUFFER 2>&1) == '' ]] {
        zle .accept-line
    } else {
        LBUFFER+=$'\n'
    }
}
zle -N qc-accept-line
bindkey '^M' qc-accept-line

# Trim trailing whitespace from pasted text
# Ref: https://unix.stackexchange.com/questions/693118
qc-trim-paste() {
    zle .bracketed-paste
    LBUFFER=${LBUFFER%%[[:space:]]##}
}
zle -N bracketed-paste qc-trim-paste

# Change '...' to '../..'
# Ref: https://grml.org/zsh/zsh-lovers.html#_completion
qc-rationalize-dot() {
    if [[ $LBUFFER == *.. ]] {
        LBUFFER+='/..'
    } else {
        LBUFFER+='.'
    }
}
zle -N qc-rationalize-dot
bindkey '.' qc-rationalize-dot
bindkey '^[.' self-insert-unmeta  # [Alt-.] Insert dot

# [Ctrl-L] Clear screen but keep scrollback
# Ref: https://superuser.com/questions/1389834
# FIXME: buggy in tmux
qc-clear-screen() {
    local prompt_height=$(echo -n ${(%%)PS1} | wc -l)
    local lines=$((LINES - prompt_height))
    printf "$terminfo[cud1]%.0s" {1..$lines}  # cursor down
    printf "$terminfo[cuu1]%.0s" {1..$lines}  # cursor up
    zle .reset-prompt
}
zle -N qc-clear-screen
bindkey '^L' qc-clear-screen

# [Ctrl-R] Search history by fzf-tab
# Ref: https://github.com/Aloxaf/dotfiles/blob/0619025cb2/zsh/.config/zsh/snippets/key-bindings.zsh#L80-L102
qc-search-history() {
    local result=$(fc -rl 1 | ftb-tmux-popup -n '2..' --scheme=history --query=$BUFFER)
    [[ $result != '' ]] && zle .vi-fetch-history -n $result
    zle .reset-prompt
}
zle -N qc-search-history
bindkey '^R' qc-search-history

# [Ctrl-N] Navigate by xplr
# This is not a widget since properly resetting prompt is hard
# See https://github.com/romkatv/powerlevel10k/issues/72
bindkey -s '^N' '^Q cd -- ${$(xplr):-.} \n'

#===================#
# Plugins (Part II) #
#===================#

zcomet compinit

zcomet load Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
# zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

# FIXME: highlight for partial accept is incorrect
zcomet load zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=true
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
    qc-up-line-or-search
    qc-down-line-or-search
    qc-accept-line
)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(
    qc-forward-subword
    qc-forward-shellword
)

zcomet load zdharma-continuum/fast-syntax-highlighting
unset 'FAST_HIGHLIGHT[chroma-man]'  # chroma-man will stuck history browsing

zcomet load romkatv/powerlevel10k

#=========#
# Configs #
#=========#

# zsh misc
setopt auto_cd               # simply type dir name to cd
setopt auto_pushd            # make cd behave like pushd
setopt pushd_ignore_dups     # don't pushd duplicates
setopt pushd_minus           # exchange the meanings of `+` and `-` in pushd
setopt interactive_comments  # comments in interactive shells
setopt multios               # multiple redirections
setopt ksh_option_print      # make setopt output all options
setopt extended_glob         # extended globbing
setopt glob_dots             # match hidden files like `PATTERN(D)`, also affect completion
# setopt no_bare_glob_qual     # disable `PATTERN(QUALIFIERS)`, extended_glob has `PATTERN(#qQUALIFIERS)`
unsetopt short_loops         # disallow for loops without a sublist
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'  # without `/=`
autoload -Uz colors && colors  # provide color variables (see `which colors`)

# zsh history
setopt hist_ignore_all_dups  # no duplicates
setopt hist_save_no_dups     # don't save duplicates
setopt hist_ignore_space     # no commands starting with space
setopt hist_reduce_blanks    # remove all unneccesary spaces
setopt share_history         # share history between sessions
HISTFILE=~zdot/.zsh_history
HISTSIZE=1000000  # number of commands that are loaded
SAVEHIST=1000000  # number of commands that are stored

# zsh prompt
setopt transient_rprompt       # remove rprompt after accept line
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

# gpg
export GPG_TTY=$TTY

# less
export LESS='--quit-if-one-screen --RAW-CONTROL-CHARS --chop-long-lines'

# bat
export BAT_THEME='OneHalfDark'

# man
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

# npm
export NPM_CONFIG_PREFIX=~/.local
export NPM_CONFIG_CACHE=~cache/npm
# export NPM_CONFIG_PROXY=$MY_PROXY

#=========#
# Aliases #
#=========#

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

alias -g :color='--color=always'
# TODO: find a better way to specify file extension (use TMPSUFFIX for now)
alias -g :input='=(echo $fg[magenta]">>>>> Input:"$reset_color >&2; cat)'

#=========#
# Scripts #
#=========#

include -c thefuck --alias
include -c direnv hook zsh
include -f ~zdot/p10k.zsh
# include -f /opt/intel/oneapi/setvars.sh

# Enable alternate-scroll-mode
# Ref: https://github.com/microsoft/terminal/discussions/14076
printf '\e[?1007h'
