include() {
    local opt=$1; shift
    case $opt {
    -f)
        [[ -f $1 ]] && source $1
        ;;
    -c)
        (( $+commands[$1] )) || return
        local cache=/tmp/zsh-cmdcache-$(md5sum <<< $@)
        if [[ ! -f $cache ]] {
            local output=$($@)
            eval $output
            echo $output > $cache &!
        } else {
            source $cache
            (
                local output=$($@)
                if [[ $output != $(<$cache) ]] {
                    echo $output > $cache
                    echo "Cache updated: '$@' (will be applied next time)"
                }
            ) &!
        }
        ;;
    *)
        echo 'Unknown argument!' >&2
        return 1
        ;;
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

typeset -U path  # set unique (fpath has been set unique)
path=(
    $ZDOTDIR/scripts
    ~/.local/bin
    ~/.cargo/bin
    ~/.ghcup/bin
    ~/go/bin
    $path
)

include -f ~/.nix-profile/etc/profile.d/nix.sh
include -f ~/.opam/opam-init/init.zsh
