#==========#
# Internal #
#==========#

_qc-source() { [[ -r $1 ]] && source $1 }
_qc-eval()   { (( $+commands[$1] )) && smartcache eval $@ }
_qc-comp()   { (( $+commands[$1] )) && smartcache comp $@ }

#=====================#
# Directory Shortcuts #
#=====================#

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME

hash -d zdot=$ZDOTDIR

hash -d Downloads=~/Downloads
hash -d Workspace=~/Workspace
hash -d OneDrive=~/OneDrive
for p in ~Workspace/*(N) ~OneDrive/*(N); hash -d ${p:t}=$p

#=====================#
# P10k Instant Prompt #
#=====================#

_qc-source ~cache/p10k-instant-prompt-${(%):-%n}.zsh

#==================#
# Plugins (Part 1) #
#==================#

[[ -d ~zdot/.zcomet ]] || git clone https://github.com/agkozak/zcomet ~zdot/.zcomet/bin

source ~zdot/.zcomet/bin/zcomet.zsh

# update every 7 days
_qc_last_update=(~zdot/.zcomet/update(Nm-7))
if [[ -z $_qc_last_update ]] {
    touch ~zdot/.zcomet/update
    zcomet self-update
    zcomet update
    zcomet compile ~zdot/*.zsh  # NOTE: https://github.com/romkatv/zsh-bench#cutting-corners
}

zcomet fpath zsh-users/zsh-completions src
zcomet fpath nix-community/nix-zsh-completions

zcomet load tj/git-extras etc/git-extras-completion.zsh
zcomet load trapd00r/LS_COLORS lscolors.sh
zcomet load QuarticCat/zsh-smartcache
zcomet load chisui/zsh-nix-shell
zcomet load romkatv/zsh-no-ps2

AUTOPAIR_SPC_WIDGET=magic-space
AUTOPAIR_BKSPC_WIDGET=backward-delete-char
AUTOPAIR_DELWORD_WIDGET=backward-delete-word
zcomet load hlissner/zsh-autopair

#=========#
# Aliases #
#=========#

alias l='eza -lah --group-directories-first --git --time-style=long-iso'
alias lt='l -TI .git'
alias tm='trash-put'
alias ms='miniserve'
alias ipy='ipython --profile=qc'
alias pb='curl -F "c=@-" "http://fars.ee/?u=1"'
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias edge='microsoft-edge-stable'
alias sudo='sudo '
alias cute-dot='~QuarticCat/dotfiles/cute-dot.zsh'

alias -g :n='>/dev/null'
alias -g :nn='&>/dev/null'
alias -g :bg='&>/dev/null &!'

alias -g -- --help='--help 2>&1 | bat -pl help'

#============#
# Completion #
#============#

setopt menu_complete  # list choices when ambiguous

zstyle ':completion:*' sort         false                          # preserve inherent orders
zstyle ':completion:*' list-colors  ${(s.:.)LS_COLORS}             # colorize files & folders
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'l:|=* r:|=*'  # auto-cap, substr

zstyle ':completion:*' use-cache    true
zstyle ':completion:*' cache-policy _qc-cache-policy
_qc-cache-policy() { local f=("$1"(Nm-7)); [[ -z $f ]] }  # TTL = 7 days

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages'     format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings'     format '%F{red}-- no matches found --%f'

zstyle ':completion:*:-tilde-:*' tag-order !users  # no `~user`

zstyle ':completion:*:manuals'   separate-sections true  # group candidates by sections
zstyle ':completion:*:manuals.*' insert-sections   true  # `man strstr` -> `man 3 strstr`

compdef _qc-complete-galias -first-
_qc-complete-galias() {
    [[ $PREFIX != :* ]] && return
    local des=()
    printf -v des '\%s:%s' ${(kv)galiases}
    _describe 'galias' des
}

compdef _precommand bench-mode.zsh
compdef _precommand lldb.zsh

#===========#
# Functions #
#===========#

open() {
    xdg-open $@ &>/dev/null &!
}

reboot-to-windows() {
    [[ $(efibootmgr) =~ 'Boot([[:xdigit:]]*)\* Windows' ]] &&
    sudo efibootmgr --bootnext $match[1] &&
    reboot
}

#==============#
# Key Bindings #
#==============#

bindkey '\C-Z' undo
bindkey '\C-Y' redo

# Ref: https://github.com/marlonrichert/zsh-edit
qc-word-widgets() {
    local wordpat='[[:WORD:]]##|[[:space:]]##|[^[:WORD:][:space:]]##'
    local words=(${(Z:n:)BUFFER}) lwords=(${(Z:n:)LBUFFER})
    case $WIDGET {
        (*sub-l)   local move=-${(N)LBUFFER%%$~wordpat} ;;
        (*sub-r)   local move=+${(N)RBUFFER##$~wordpat} ;;
        (*shell-l) local move=-${(N)LBUFFER%$lwords[-1]*} ;;
        (*shell-r) local move=+${(N)RBUFFER#*${${words[$#lwords]#$lwords[-1]}:-$words[$#lwords+1]}} ;;
    }
    case $WIDGET {
        (*kill*) (( MARK = CURSOR + move )); zle -f kill; zle kill-region ;;
        (*)      (( CURSOR += move )) ;;
    }
}
for w in qc{,-kill}-{sub,shell}-{l,r}; zle -N $w qc-word-widgets
bindkey '\E[1;5D' qc-sub-l         # [Ctrl+Left]
bindkey '\E[1;5C' qc-sub-r         # [Ctrl+Right]
bindkey '\E[1;3D' qc-shell-l       # [Alt+Left]
bindkey '\E[1;3C' qc-shell-r       # [Alt+Right]
bindkey '\C-H'    qc-kill-sub-l    # [Ctrl+Backspace] (Konsole)
bindkey '\C-W'    qc-kill-sub-l    # [Ctrl+Backspace] (VSCode)
bindkey '\E[3;5~' qc-kill-sub-r    # [Ctrl+Delete]
bindkey '\E^?'    qc-kill-shell-l  # [Alt+Backspace]
bindkey '\E[3;3~' qc-kill-shell-r  # [Alt+Delete]
WORDCHARS='*?[]~&;!#$%^(){}<>'

# Trim trailing whitespace from pasted text
# Ref: https://unix.stackexchange.com/questions/693118
qc-trim-paste() {
    zle .bracketed-paste
    LBUFFER=${LBUFFER%%[[:space:]]#}
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
bindkey '.'   qc-rationalize-dot
bindkey '\E.' self-insert-unmeta  # [Alt+.] insert dot

# [Ctrl+L] Clear screen but keep scrollback
# Ref: https://superuser.com/questions/1389834
qc-clear-screen() {
    local prompt_height=$(print -n ${(%%)PS1} | wc -l)
    local lines=$((LINES - prompt_height))
    printf "$terminfo[cud1]%.0s" {1..$lines}  # cursor down
    printf "$terminfo[cuu1]%.0s" {1..$lines}  # cursor up
    zle .reset-prompt
}
zle -N qc-clear-screen
bindkey '\C-L' qc-clear-screen

# [Esc Esc] Correct previous command
# Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/thefuck
qc-fuck() {
    local fuck=$(THEFUCK_REQUIRE_CONFIRMATION=false thefuck $(fc -ln -1) 2>/dev/null)
    if [[ $fuck != '' ]] {
        compadd -Q $fuck
    } else {
        compadd -x '%F{red}-- no fucks given --%f'
    }
}
zle -C qc-fuck complete-word qc-fuck
bindkey '\E\E' qc-fuck

#==================#
# Plugins (Part 2) #
#==================#

zcomet compinit

zcomet load Aloxaf/fzf-tab  # TODO: run `build-fzf-tab-module` after update
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

zcomet load zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=true
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(qc-{sub,shell}-r)

zcomet load zdharma-continuum/fast-syntax-highlighting
unset 'FAST_HIGHLIGHT[chroma-man]'  # chroma-man will stuck history browsing

zcomet load romkatv/powerlevel10k

#========#
# Config #
#========#

setopt auto_cd               # simply type dir name to `cd`
setopt auto_pushd            # make `cd` behave like pushd
setopt pushd_ignore_dups     # don't pushd duplicates
setopt pushd_minus           # exchange the meanings of `+` and `-` in pushd
setopt interactive_comments  # comments in interactive shells
setopt multios               # multiple redirections
setopt ksh_option_print      # make `setopt` output all options
setopt extended_glob         # extended globbing
setopt glob_dots             # match hidden files, also affect completion
setopt rc_quotes             # `''` -> `'` within singly quoted strings
setopt magic_equal_subst     # perform filename expansion on `any=expr` args
setopt no_flow_control       # make [Ctrl+S] and [Ctrl+Q] work

setopt hist_ignore_all_dups  # no duplicates in history list
setopt hist_save_no_dups     # no duplicates in history file
setopt hist_ignore_space     # ignore commands starting with a space
setopt hist_reduce_blanks    # remove all unnecessary spaces
setopt hist_fcntl_lock       # use fcntl to improve locking performance
HISTFILE=~zdot/.zsh_history
HISTSIZE=1000000  # number of commands that are loaded
SAVEHIST=1000000  # number of commands that are stored

TIMEFMT="\
%J   %U  user %S system %P cpu %*E total
avg shared (code):         %X KB
avg unshared (data/stack): %D KB
total (sum):               %K KB
max memory:                %M MB
page faults from disk:     %F
other page faults:         %R"

export EDITOR='nvim'
export VISUAL='nvim'

export LESS='--quit-if-one-screen --RAW-CONTROL-CHARS --chop-long-lines'

export FZF_DEFAULT_OPTS='--ansi --height=60% --reverse --cycle --bind=tab:accept'

export MINISERVE_HIDDEN=true
export MINISERVE_QRCODE=true
export MINISERVE_DIRS_FIRST=true

export BAT_THEME='OneHalfDark'
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

export GPG_TTY=$TTY
export SSH_AGENT_PID=
export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh

export CMAKE_GENERATOR='Ninja'
export CMAKE_COLOR_DIAGNOSTICS=ON
export CMAKE_EXPORT_COMPILE_COMMANDS=ON
# TODO: use mold globally

export MOLD_JOBS=1

# See https://github.com/nektos/act/issues/303#issuecomment-962403508
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock

#=========#
# Scripts #
#=========#

_qc-eval atuin init zsh --disable-up-arrow
_qc-eval direnv hook zsh

_qc-source ~zdot/p10k.zsh
