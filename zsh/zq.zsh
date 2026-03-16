# QC's Zsh Plugin Manager
#
# Usage:
#
#   $ zq plug romkatv/zsh-no-ps2                 # load plugin
#   $ zq plug ohmyzsh/ohmyzsh plugins/sudo       # load plugin in specific sub-folder
#   $ zq plug ohmyzsh/ohmyzsh lib/clipboard.zsh  # load specific shell script
#   $ zq update                                  # update all plugins
#   $ zq outdated 7 && zq update                 # update every 7 days
#
# Files are stored at `$ZQ_DIR`, which is `~/.local/share/zq` by default.

ZQ_DIR=${ZQ_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zq}

zq() {
    emulate -LR zsh -o extended_glob -o err_return
    _zq-$1 "${@:2}"
}

_zq-plug() {  # <repo> [<dir>|<file>]
    local repo_dir=$ZQ_DIR/repos/$1
    if [[ ! -d $repo_dir ]] {
        printf "\e[1m\e[33m$1\e[0m\n"
        git clone --depth=1 https://github.com/$1 $repo_dir
        { for file in $repo_dir/**/*.zsh{,-theme}(N.); zcompile $file; } &!
    }

    if [[ $2 == '' ]] {
        local targets=($repo_dir/${1:t}.{zsh-theme,plugin.zsh}(N))
    } elif [[ -d $repo_dir/$2 ]] {
        local targets=($repo_dir/$2/*.{zsh-theme,plugin.zsh}(N))
    } else {
        local targets=($repo_dir/$2)
    }
    source $targets[1]
}

_zq-update() {
    autoload -Uz zargs
    zargs -P8 -l1 -r -- $ZQ_DIR/repos/*/*(N/) -- _zq-update-repo
    mkdir -p $ZQ_DIR && touch $ZQ_DIR/update
}

_zq-update-repo() {  # <dir>
    local output=$(git -C $1 -c color.ui=always pull 2>&1)
    [[ $output == 'Already up to date.' ]] && return
    printf "\e[1m\e[33m${1:h:t}/${1:t}\e[0m\n$output\n"
    { for file in $1/**/*.zsh{,-theme}(N.); zcompile $file; } &!
}

_zq-outdated() {  # <days>
    local last_update=($ZQ_DIR/update(Nm-$1))
    [[ $last_update == '' ]]
}
