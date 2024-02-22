include() {
    local opt=$1; shift
    case $opt {
    (-f)
        [[ -f $1 ]] && source $1 ;;
    (-c)
        # Ref: https://github.com/QuarticCat/zsh-smartcache
        (( $+commands[$1] )) || return
        local hashval=$(md5sum <<< $@)
        local cache=/tmp/zsh-cmdcache-${hashval:0:32}
        if [[ ! -f $cache ]] {
            local output=$($@)
            eval $output
            printf '%s' $output > $cache &!
        } else {
            source $cache
            {
                local output=$($@)
                if [[ $output != $(<$cache) ]] {
                    printf '%s' $output > $cache
                    echo "Cache updated: '$@' (will be applied next time)"
                }
            } &!
        } ;;
    }
}

export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share

export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'
export SDL_IM_MODULE='fcitx'
export GLFW_IM_MODULE='ibux'

export EDITOR='vim'
export VISUAL='vim'

ZDOTDIR=$XDG_CONFIG_HOME/zsh

typeset -U path  # set unique (fpath is already unique)
path=(
    $ZDOTDIR/scripts
    ~/.local/bin
    ~/.cargo/bin
    ~/.ghcup/bin
    ~/go/bin
    $path
)
