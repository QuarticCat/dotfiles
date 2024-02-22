#=====================#
# Directory Shortcuts #
#=====================#

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME

hash -d zdot=$ZDOTDIR
hash -d git-exclude=.git/info/exclude

hash -d Downloads=~/Downloads
hash -d Workspace=~/Workspace
hash -d OneDrive=~/OneDrive
for p in ~Workspace/*(N) ~OneDrive/*(N); hash -d ${p:t}=$p

#=====================#
# P10k Instant Prompt #
#=====================#

include -f ~cache/p10k-instant-prompt-${(%):-%n}.zsh

#==================#
# Plugins (Part 1) #
#==================#

[[ -d ~zdot/.zcomet ]] ||
git clone https://github.com/agkozak/zcomet ~zdot/.zcomet/bin

source ~zdot/.zcomet/bin/zcomet.zsh

zcomet load ohmyzsh lib {completion,clipboard}.zsh
zcomet load ohmyzsh plugins/sudo
zcomet load ohmyzsh plugins/extract

zcomet load tj/git-extras etc git-extras-completion.zsh

zcomet load chisui/zsh-nix-shell

zcomet load hlissner/zsh-autopair
AUTOPAIR_BKSPC_WIDGET='backward-delete-char'

#=============#
# Completions #
#=============#

# general
zstyle ':completion:*' sort false
zstyle ':completion:*' special-dirs false  # exclude `.` and `..` (enabled by OMZL::completion.zsh)

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
    (bk)
        local base=~Books
        local result=$(fd --base-directory=$base --type=file | fzf)
        [[ $result != '' ]] && open $base/$result ;;
    (hw)
        local base=~Homework
        local result=$(fd --base-directory=$base --type=directory --max-depth=2 | fzf)
        [[ $result != '' ]] && open $base/$result ;;
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
        zle -f kill
        zle .kill-region
    } else {
        (( CURSOR += move ))
    }
}
for w in qc-{back,for}ward-{,kill-}{sub,shell}word; zle -N $w qc-word-widgets
bindkey '^[[1;5D' qc-backward-subword         # [Ctrl-Left]
bindkey '^[[1;5C' qc-forward-subword          # [Ctrl-Right]
bindkey '^[[1;3D' qc-backward-shellword       # [Alt-Left]
bindkey '^[[1;3C' qc-forward-shellword        # [Alt-Right]
bindkey '^H'      qc-backward-kill-subword    # [Ctrl-Backspace] (in Konsole)
bindkey '^W'      qc-backward-kill-subword    # [Ctrl-Backspace] (in VSCode)
bindkey '^[[3;5~' qc-forward-kill-subword     # [Ctrl-Delete]
bindkey '^[^?'    qc-backward-kill-shellword  # [Alt-Backspace]
bindkey '^[[3;3~' qc-forward-kill-shellword   # [Alt-Delete]

# [Enter] Insert `\n` when accept-line would result in a parse error or PS2
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

# Change `...` to `../..`
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
qc-clear-screen() {
    local prompt_height=$(echo -n ${(%%)PS1} | wc -l)
    local lines=$((LINES - prompt_height))
    printf "$terminfo[cud1]%.0s" {1..$lines}  # cursor down
    printf "$terminfo[cuu1]%.0s" {1..$lines}  # cursor up
    zle .reset-prompt
}
zle -N qc-clear-screen
bindkey '^L' qc-clear-screen

# TODO: [Shift-Del] Remove last history entry

#==================#
# Plugins (Part 2) #
#==================#

zcomet compinit

# ORDER: after `compinit` & before zsh-autosuggestions, fast-syntax-highlighting
zcomet load Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

zcomet load zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=true
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
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
setopt auto_cd               # simply type dir name to `cd`
setopt auto_pushd            # make `cd` behave like pushd
setopt pushd_ignore_dups     # don't pushd duplicates
setopt pushd_minus           # exchange the meanings of `+` and `-` in pushd
setopt interactive_comments  # comments in interactive shells
setopt multios               # multiple redirections
setopt ksh_option_print      # make `setopt` output all options
setopt extended_glob         # extended globbing
setopt glob_dots             # match hidden files like `PATTERN(D)`, also affect completion
unsetopt short_loops         # disable for-loops without a sublist
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
MY_PROXY='socks5h://127.0.0.1:1089'

# fzf
export FZF_DEFAULT_OPTS='--ansi --height=60% --reverse --cycle --bind=tab:accept'

# gpg-agent
export GPG_TTY=$TTY
export SSH_AGENT_PID=
export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh

# less
export LESS='--quit-if-one-screen --RAW-CONTROL-CHARS --chop-long-lines'

# bat
export BAT_THEME='OneHalfDark'

# man
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

# miniserve
export MINISERVE_HIDDEN=true
export MINISERVE_QRCODE=true
export MINISERVE_DIRS_FIRST=true

#=========#
# Aliases #
#=========#

alias l='eza -lah --group-directories-first --git --time-style=long-iso'
alias lt='l -TI .git'
alias tm='trash-put'
alias ms='miniserve'
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias edge='microsoft-edge-stable'
alias pb='curl -F "c=@-" "http://fars.ee/?u=1"'
alias sudo='sudo '
alias pc='proxychains -q '
alias env-proxy='         \
    http_proxy=$MY_PROXY  \
    HTTP_PROXY=$MY_PROXY  \
    https_proxy=$MY_PROXY \
    HTTPS_PROXY=$MY_PROXY '
alias cute-dot='~QuarticCat/dotfiles/cute-dot.zsh'

# Ref: https://unix.stackexchange.com/questions/70963
alias -g :n='>/dev/null'
alias -g :nn='&>/dev/null'
alias -g :bg='&>/dev/null &!'

#=========#
# Scripts #
#=========#

include -c atuin init zsh --disable-up-arrow
include -c thefuck --alias
include -c direnv hook zsh
include -f ~zdot/p10k.zsh
