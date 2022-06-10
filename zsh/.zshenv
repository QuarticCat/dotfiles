include() {
    local opt=$1; shift
    case $opt {
    -f)
        [[ -f $1 ]] && source $1
        ;;
    -c)
        # not cached
        (( $+commands[$1] )) && eval "$($@)"

        # # cached
        # if (( $+commands[$1] )) {
        #     local cache=/tmp/zsh-cmdcache-$1
        #     if [[ -f $cache ]] {
        #         source $cache
        #     } else {
        #         eval "$($@)"
        #     }
        #     $@ > $cache &!  # update cache in the background
        # }
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

export INPUT_METHOD='fcitx5'
export GTK_IM_MODULE='fcitx5'
export QT_IM_MODULE='fcitx5'
export XMODIFIERS='@im=fcitx5'

export EDITOR='vim'
export VISUAL='vim'

ZDOTDIR=$XDG_CONFIG_HOME/zsh

typeset -U path  # set unique (fpath has been set unique)
path=(
    ~/.local/bin
    ~/.cargo/bin
    ~/.ghcup/bin
    ~/go/bin
    $path
)

include -f ~/.nix-profile/etc/profile.d/nix.sh
include -f ~/.opam/opam-init/init.zsh
