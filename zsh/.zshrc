#==========#
# Internal #
#==========#

bindkey -e  # use Emacs keymap

_qc-source() { [[ -r $1 ]] && source $1 }
_qc-eval()   { (( $+commands[$1] )) && smartcache eval $@ }
_qc-comp()   { (( $+commands[$1] )) && smartcache comp $@ }

# Placed ahead since it modifies $PATH and $FPATH
if [[ $OSTYPE == darwin* ]] {
    # NOTE: it detects $PATH to decide output so smartcache is not feasible
    eval $(/opt/homebrew/bin/brew shellenv)
}

#=====================#
# Directory Shortcuts #
#=====================#

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME
hash -d state=$XDG_STATE_HOME

hash -d zdot=$ZDOTDIR

hash -d Downloads=~/Downloads
hash -d Workspace=~/Workspace
hash -d OneDrive=~/OneDrive
for p in ~Workspace/*(/N) ~OneDrive/*(/N); hash -d ${p:t}=$p
hash -d Memo=~/OneDrive/Apps/Graph/Main
hash -d WeChat=~/Documents/WeChat_Data/xwechat_files

#==================#
# Plugins (Part 1) #
#==================#

[[ -d ~zdot/.zcomet ]] || git clone https://github.com/agkozak/zcomet ~zdot/.zcomet/bin

source ~zdot/.zcomet/bin/zcomet.zsh

# Update every 7 days
_qc_last_update=(~zdot/.zcomet/update(Nm-7))
if [[ -z $_qc_last_update ]] {
    touch ~zdot/.zcomet/update
    zcomet self-update
    zcomet update
    zcomet compile ~zdot/*.zsh  # NOTE: https://github.com/romkatv/zsh-bench#cutting-corners
} else {
    # Start p10k instant prompt only when no update
    # Otherwise update logs might not be displayed
    _qc-source ~cache/p10k-instant-prompt-${(%):-%n}.zsh
}

zcomet fpath zsh-users/zsh-completions src
zcomet fpath nix-community/nix-zsh-completions

zcomet load tj/git-extras etc/git-extras-completion.zsh
zcomet load trapd00r/LS_COLORS lscolors.sh
zcomet load QuarticCat/zsh-smartcache
zcomet load chisui/zsh-nix-shell
zcomet load romkatv/zsh-no-ps2

zcomet load ohmyzsh lib clipboard.zsh
zcomet load ohmyzsh plugins/sudo

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
alias ms='miniserve -vqHDp 58080 --random-route'
alias ipy='ipython --profile=qc'
alias clc='clipcopy'
alias clp='clippaste'
alias pb='curl -F "c=@-" "http://fars.ee/?u=1"'
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias edge='microsoft-edge-stable'
alias sudo='sudo '
alias cute-dot='~QuarticCat/dotfiles/cute-dot.zsh'

alias -g :n='>/dev/null'
alias -g :nn='&>/dev/null'
alias -g :bg='&>/dev/null &!'
alias -g :h='--help 2>&1 | bat -pl help'

if [[ $OSTYPE == linux* ]] {
    alias open='xdg-open'
    alias strace='strace --seccomp-bpf --string-limit=9999'
}

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

zstyle ':completion:*:processes'       command 'ps xwwo pid,user,comm,cmd'  # for kill
zstyle ':completion:*:processes-names' command 'ps xwwo comm'               # for killall
zstyle ':completion:*:process-groups'  hidden  all                          # no `0`

compdef _qc-complete-galias -first-
_qc-complete-galias() {
    [[ $PREFIX != :* ]] && return
    local des=()
    printf -v des '\%s:%s' ${(kv)galiases}
    _describe 'galias' des
}

compdef _precommand bench-mode.zsh
compdef _precommand lldb.zsh

if [[ $OSTYPE == darwin* ]] {
    _qc-comp rustup completions zsh rustup
    _qc-comp rustup completions zsh cargo
}

#===========#
# Functions #
#===========#

_qc_bg_cmds=(
    xdg-open                       # misc
    hotspot nsys-ui                # profilers
    firefox microsoft-edge-stable  # browsers
)
for cmd in $_qc_bg_cmds; $cmd() { command $0 $@ &>/dev/null &! }

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
bindkey '\C-U' backward-kill-line

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
        (*kill*) (( MARK = CURSOR + move )); zle -f kill; zle .kill-region ;;
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

# Trim trailing spaces from pasted text
# Ref: https://unix.stackexchange.com/questions/693118
qc-trim-paste() {
    zle .$WIDGET && LBUFFER=${LBUFFER%%[[:space:]]#}
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

#=======#
# Hooks #
#=======#

autoload -Uz add-zsh-hook

# [PRECMD] Reset cursor shape as some programs (nvim, yazi) will change it
_qc-reset-cursor() {
    print -n '\E[5 q'  # line cursor
}
add-zsh-hook precmd _qc-reset-cursor

# Inside distrobox, execute commands on host when not found
# Ref: https://github.com/89luca89/distrobox/blob/main/docs/posts/execute_commands_on_host.md
if [[ -e /run/.containerenv || -e /.dockerenv ]] {
    command_not_found_handler() { distrobox-host-exec "$@" }
}

#==================#
# Plugins (Part 2) #
#==================#

zcomet compinit

zcomet load Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' prefix       ''
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps hwwo cmd --pid=$word'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags   '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*'             popup-pad   0 3

zcomet load zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=true
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(qc-{sub,shell}-r)

zcomet load zdharma-continuum/fast-syntax-highlighting
unset 'FAST_HIGHLIGHT[chroma-man]'  # buggy: stuck history browsing
unset 'FAST_HIGHLIGHT[chroma-ssh]'  # buggy: incorrect

zcomet load romkatv/powerlevel10k

#========#
# Config #
#========#

setopt auto_cd               # simply type dir name to `cd`
setopt auto_pushd            # make `cd` behave like pushd
setopt pushd_ignore_dups     # don't pushd duplicates
setopt pushd_minus           # exchange the meanings of `+` and `-` in pushd
setopt interactive_comments  # comments in interactive shells
setopt extended_glob         # extended globbing
setopt glob_dots             # match hidden files, also affect completion
setopt rc_quotes             # `''` -> `'` within singly quoted strings
setopt magic_equal_subst     # perform filename expansion on `any=expr` args
setopt no_flow_control       # don't occupy [Ctrl+S] and [Ctrl+Q]

setopt hist_ignore_all_dups  # no duplicate in history list
setopt hist_save_no_dups     # no duplicate in history file
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

if [[ $DISPLAY != '' || $TERM_PROGRAM == vscode ]] {
    export EDITOR='code --wait'
} else {
    export EDITOR='vim'
}

export GPG_TTY=$TTY

if [[ $OSTYPE == linux* ]] {
    export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
}

export LESS='--quit-if-one-screen --RAW-CONTROL-CHARS --chop-long-lines'

export FZF_DEFAULT_OPTS='--ansi --height=60% --reverse --cycle --bind=tab:accept'

export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

export MOLD_JOBS=1

export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive  # see https://nixos.wiki/wiki/Locales

export RUSTUP_DIST_SERVER='https://rsproxy.cn'         # mirror for `rustup update`
export RUSTUP_UPDATE_ROOT='https://rsproxy.cn/rustup'  # mirror for `rustup self update`

#=========#
# Scripts #
#=========#

_qc-eval atuin init zsh --disable-up-arrow
_qc-eval direnv hook zsh

_qc-source ~zdot/p10k.zsh
