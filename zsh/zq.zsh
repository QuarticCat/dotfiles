# QC's Zsh Plugin Manager
#
# Usage:
#
#   $ zq plug romkatv/zsh-no-ps2                 # load plugin
#   $ zq plug ohmyzsh/ohmyzsh plugins/sudo       # load plugin in specific sub-folder
#   $ zq plug ohmyzsh/ohmyzsh lib/clipboard.zsh  # load specific shell script
#   $ zq update                                  # update all plugins after cooldown
#   $ zq outdated 7 && zq update                 # update every 7 days
#
# Files are stored at `$ZQ_DIR`, which is `~/.local/share/zq` by default.
# Set `$ZQ_COOLDOWN_DAYS` to change the cooldown, which defaults to 30 days.

#========#
# Config #
#========#

ZQ_DIR=${ZQ_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zq}
ZQ_COOLDOWN_DAYS=${ZQ_COOLDOWN_DAYS:-30}

#===================#
# Private Functions #
#===================#

_zq_cooldown_commit() {  # <dir> <rev>
    local commit=$(git -C $1 rev-list -1 --first-parent --before="$ZQ_COOLDOWN_DAYS days ago" $2)
    [[ $commit == '' ]] && return 1
    print -r -- $commit
}

_zq_update_repo() {  # <dir>
    git -C $1 fetch --quiet --filter=tree:0
    local commit=$(_zq_cooldown_commit $1 origin/HEAD) || return
    [[ $commit == $(git -C $1 rev-parse HEAD) ]] && return
    git -C $1 checkout -q --detach $commit
    printf "\e[1m\e[33m${1:h:t}/${1:t}\e[0m\n$commit\n"
    { for file in $1/**/*.zsh{,-theme}(N.); zcompile $file; } &!
}

#==================#
# Public Functions #
#==================#

_zq-plug() {  # <repo> [<dir>|<file>]
    local repo_dir=$ZQ_DIR/repos/$1
    if [[ ! -d $repo_dir ]] {
        printf "\e[1m\e[33m$1\e[0m\n"
        git clone --filter=tree:0 --no-checkout https://github.com/$1 $repo_dir
        local commit=$(_zq_cooldown_commit $repo_dir HEAD) || return
        git -C $repo_dir checkout -q $commit
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
    mkdir -p $ZQ_DIR && touch $ZQ_DIR/update
    autoload -Uz zargs
    zargs -P8 -l1 -r -- $ZQ_DIR/repos/*/*(N/) -- _zq_update_repo
}

_zq-outdated() {  # <days>
    local last_update=($ZQ_DIR/update(Nm-$1))
    [[ $last_update == '' ]]
}

zq() {
    emulate -LR zsh -o extended_glob
    _zq-$1 "${@:2}"
}
