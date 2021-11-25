include() {
    case $1 in
    -f)
        [[ -f $2 ]] && source $2
        ;;
    -c)
        local output=$($=2) &>/dev/null && eval $output
        ;;
    *)
        echo 'Unknown argument!' >&2
        return 1
        ;;
    esac
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

typeset -U path  # set unique
path=(
    ~/.local/bin
    ~/.cargo/bin
    ~/.ghcup/bin
    /opt/riscv/bin
    $path
)

include -f ~/.nix-profile/etc/profile.d/nix.sh
include -f ~/.opam/opam-init/init.zsh
