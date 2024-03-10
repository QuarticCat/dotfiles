export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share

export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'
export SDL_IM_MODULE='fcitx'
export GLFW_IM_MODULE='ibux'

export EDITOR='nvim'
export VISUAL='nvim'

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
