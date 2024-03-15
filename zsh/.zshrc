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
    # build-fzf-tab-module
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

bindkey '^['   send-break          # [Esc]
bindkey '^[[D' backward-char       # [Left]      vi-backward-char can't cross lines
bindkey '^[[C' forward-char        # [Right]     vi-forward-char can't cross lines
bindkey '^A'   beginning-of-line   # [Ctrl+A]
bindkey '^E'   end-of-line         # [Ctrl+E]
bindkey '^Z'   undo                # [Ctrl+Z]
bindkey '^Y'   redo                # [Ctrl+Y]
bindkey '^Q'   push-line-or-edit   # [Ctrl+Q]
bindkey '^[^M' self-insert-unmeta  # [Alt+Enter]

# Ref: https://github.com/marlonrichert/zsh-edit
qc-word-widgets() {
    if [[ $WIDGET == *-shellword ]] {
        local words=(${(Z:n:)BUFFER}) lwords=(${(Z:n:)LBUFFER})
        if [[ $WIDGET == *-backward-* ]] {
            local tail=$lwords[-1]
            local move=-${(N)LBUFFER%$tail*}
        } else {
            local head=${${words[$#lwords]#$lwords[-1]}:-$words[$#lwords+1]}
            local move=+${(N)RBUFFER#*$head}
        }
    } else {
        local subword='([[:WORD:]]##~*[^[:upper:]]*[[:upper:]]*~*[[:alnum:]]*[^[:alnum:]]*)'
        local word="(${subword}|[^[:WORD:][:space:]]##|[[:space:]]##)"
        if [[ $WIDGET == *-backward-* ]] {
            local move=-${(N)LBUFFER%%${~word}(?|)}
        } else {
            local move=+${(N)RBUFFER##(?|)${~word}}
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
bindkey '^[[1;5D' qc-backward-subword         # [Ctrl+Left]
bindkey '^[[1;5C' qc-forward-subword          # [Ctrl+Right]
bindkey '^[[1;3D' qc-backward-shellword       # [Alt+Left]
bindkey '^[[1;3C' qc-forward-shellword        # [Alt+Right]
bindkey '^H'      qc-backward-kill-subword    # [Ctrl+Backspace] (Konsole)
bindkey '^W'      qc-backward-kill-subword    # [Ctrl+Backspace] (VSCode)
bindkey '^[[3;5~' qc-forward-kill-subword     # [Ctrl+Delete]
bindkey '^[^?'    qc-backward-kill-shellword  # [Alt+Backspace]
bindkey '^[[3;3~' qc-forward-kill-shellword   # [Alt+Delete]

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
bindkey '.' qc-rationalize-dot
bindkey '^[.' self-insert-unmeta  # [Alt+.] insert dot

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
bindkey '^L' qc-clear-screen

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
bindkey '\e\e' qc-fuck

#==================#
# Plugins (Part 2) #
#==================#

zcomet compinit

zcomet load Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

zcomet load zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=true
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(qc-accept-line)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(qc-forward-{sub,shell}word)

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
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'  # without `/=`
autoload -Uz colors && colors  # provide color variables (see `which colors`)

setopt hist_ignore_all_dups  # no duplicates in history list
setopt hist_save_no_dups     # no duplicates in history file
setopt hist_ignore_space     # ignore commands starting with a space
setopt hist_reduce_blanks    # remove all unnecessary spaces
setopt hist_fcntl_lock       # use fcntl to improve locking performance
setopt share_history         # share history between sessions
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

export MOLD_JOBS=1

#=========#
# Scripts #
#=========#

_qc-eval atuin init zsh --disable-up-arrow
_qc-eval direnv hook zsh

_qc-source ~zdot/p10k.zsh
