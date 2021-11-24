##
## Star tmux
##

# # if (not in tmux) and (interactive env) and (not embedded terminal)
# [[ -z $TMUX && $- == *i* && ! $(</proc/$PPID/cmdline) =~ "dolphin|vim|emacs|code" ]] && tmux

##
## Directory shortcuts
##

hash -d config=$XDG_CONFIG_HOME
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME
hash -d zdot=$ZDOTDIR

hash -d OneDrive=~/OneDrive
hash -d Downloads=~/Downloads
hash -d Workspace=~/Workspace
for p in ~Workspace/*; hash -d $(basename $p)=$p
for p in ~Code/*; hash -d $(basename $p)=$p

##
## Start p10k instant prompt
##

include -f ~config/p10k-instant-prompt-${(%):-%n}.zsh

##
## Load plugins
##

include -f ~zdot/.zgenom/zgenom.zsh

zgenom autoupdate  # every 7 days

if ! zgenom saved; then
    zgenom load romkatv/powerlevel10k powerlevel10k

    zgenom ohmyzsh lib/completion.zsh
    zgenom ohmyzsh lib/clipboard.zsh

    zgenom ohmyzsh plugins/extract
    zgenom ohmyzsh plugins/pip

    zgenom ohmyzsh --completion plugins/rust
    zgenom ohmyzsh --completion plugins/docker-compose
    zgenom load --completion spwhitt/nix-zsh-completions

    zgenom load Aloxaf/fzf-tab  # TODO: move `compinit` before this?
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-autosuggestions
    zgenom load zsh-users/zsh-history-substring-search
    zgenom load hlissner/zsh-autopair
    zgenom load ~zdot/snippets/key-bindings.zsh

    zgenom save

    zgenom compile ~zdot
fi

fpath=(
    ~zdot/completions
    ~zdot/functions
    $fpath
)
autoload -Uz ~zdot/functions/*(:t)

##
## Configurations
##

# zsh misc
setopt auto_cd               # simply type dir name to cd
setopt auto_pushd            # make cd behaves like pushd
setopt pushd_ignore_dups     # don't pushd duplicates
setopt pushd_minus           # exchange the meanings of `+` and `-` in pushd
setopt interactive_comments  # comments in interactive shells
setopt multios               # multiple redirections
setopt ksh_option_print      # make setopt output all options
setopt extended_glob         # extended globbing
setopt no_bare_glob_qual     # disable `PATTERN(QUALIFIERS)`, extended_glob has `PATTERN(#qQUALIFIERS)`
WORDCHARS='*?.~-_&!#$%^<>'

# zsh history
setopt hist_ignore_all_dups  # no duplicates
setopt hist_save_no_dups     # don't save duplicates
setopt hist_ignore_space     # no commands starting with space
setopt hist_reduce_blanks    # remove all unneccesary spaces
setopt share_history         # share history between sessions
HISTFILE=~zdot/.zsh_history
HISTSIZE=50000
SAVEHIST=10000

# zsh completion
compdef _galiases -first-
_galiases() {
    if [[ $PREFIX == :* ]]; then
        local des
        for k v ("${(@kv)galiases}") des+=("${k//:/\\:}:alias -g '$v'")
        _describe 'alias' des
    fi
}
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-rebase:*' sort false

# my env variables
MY_PROXY='127.0.0.1:1999'

# fzf
export FZF_DEFAULT_OPTS='--ansi --height=60% --reverse --cycle --bind=tab:accept'

# fzf-tab
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group ',' '.'  # ?
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:kill:*' popup-pad 0 3

# fast-syntax-highlighting
unset 'FAST_HIGHLIGHT[chroma-man]'  # chroma-man will stuck history browsing

# zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND='1'

# zsh-history-substring-search
HISTORY_SUBSTRING_SEARCH_FUZZY='1'

# bat
export BAT_THEME='OneHalfDark'

# man-pages
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

# rustup
export RUSTUP_DIST_SERVER='https://rsproxy.cn'
export RUSTUP_UPDATE_ROOT='https://rsproxy.cn/rustup'

# npm
export NPM_CONFIG_PREFIX=~/.local
export NPM_CONFIG_CACHE=~cache/npm
export NPM_CONFIG_PROXY=$MY_PROXY

##
## Aliases
##

alias l='exa -lah --group-directories-first --git --time-style=long-iso'
alias lt='l -TI .git'
alias clc='clipcopy'
alias clp='clippaste'
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias sudo='sudo '
alias cgp='cgproxy '
alias pc='proxychains -q '
alias open='xdg-open'
alias with-proxy=' \
    http_proxy=$MY_PROXY \
    HTTP_PROXY=$MY_PROXY \
    https_proxy=$MY_PROXY \
    HTTPS_PROXY=$MY_PROXY '

alias -g :n='/dev/null'
alias -g :bg='&>/dev/null &'
alias -g :bg!='&>/dev/null &!'  # &!: background + disown

##
## Load scripts
##

include -c 'direnv hook zsh'
include -f ~zdot/p10k.zsh
