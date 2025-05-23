export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state

if [[ $OSTYPE == linux* ]] {
    # Ref: https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland#KDE_Plasma
    export XMODIFIERS='@im=fcitx'
    if [[ $XDG_SESSION_TYPE == x11 ]] {
        export GTK_IM_MODULE='fcitx'
        export QT_IM_MODULE='fcitx'
    }
}

ZDOTDIR=$XDG_CONFIG_HOME/zsh

typeset -U fpath path  # set unique
path=(
    $ZDOTDIR/scripts
    ~/.cargo/bin
    ~/.ghcup/bin
    ~/.cache/.bun/bin
    ~/go/bin
    $path
)
