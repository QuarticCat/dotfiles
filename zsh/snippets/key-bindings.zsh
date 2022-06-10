bindkey -r '^['  # [Esc] (Default: vi-cmd-mode)

bindkey '^Z' undo         # [Ctrl-Z]
bindkey '^Y' redo         # [Ctrl-Y]
bindkey '^Q' push-line    # [Ctrl-Q]
bindkey ' '  magic-space  # [Space] Do history expansion

# Widgets are from zsh-history-substring-search
bindkey '^[[A' history-substring-search-up    # [UpArrow]
bindkey '^[[B' history-substring-search-down  # [DownArrow]

# Trim trailing newline from pasted text
bracketed-paste() {
    # Ref: https://unix.stackexchange.com/questions/693118
    zle .$WIDGET && LBUFFER=${LBUFFER%$'\n'}
}
zle -N bracketed-paste

# [Ctrl+L] clear screen while maintaining scrollback
fixed-clear-screen() {
    # Ref: https://superuser.com/questions/1389834
    # FIXME: works incorrectly in tmux
    local prompt_height=$(echo -n ${(%%)PS1} | wc -l)
    local lines=$((LINES - prompt_height))
    printf "$terminfo[cud1]%.0s" {1..$lines}  # cursor down
    printf "$terminfo[cuu1]%.0s" {1..$lines}  # cursor up
    zle reset-prompt
}
zle -N fixed-clear-screen
bindkey '^L' fixed-clear-screen

# [Ctrl-R] Search history by fzf-tab
fzf-history-search() {
    # Ref: https://github.com/Aloxaf/dotfiles/blob/0619025cb2/zsh/.config/zsh/snippets/key-bindings.zsh#L80-L102
    local selected=$(
        fc -rl 1 |
        ftb-tmux-popup -n '2..' --tiebreak=index --prompt='cmd> ' ${BUFFER:+-q$BUFFER}
    )
    if [[ $selected != '' ]] {
        zle vi-fetch-history -n $selected
    }
    zle reset-prompt
}
zle -N fzf-history-search
bindkey '^R' fzf-history-search

# [Ctrl-N] Navigate by xplr
bindkey -s '^N' '^Q cd -- ${$(xplr):-.} \n'
# xplr-navigate() {
#     local dir=$(xplr)
#     if [[ $dir != '' ]] {
#         cd -- $dir
#     }
#     zle reset-prompt
# }
# zle -N xplr-navigate
# bindkey '^N' xplr-navigate
