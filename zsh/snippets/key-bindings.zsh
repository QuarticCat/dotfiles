bindkey '^[[1;5C' forward-word    # [Ctrl-RightArrow]
bindkey '^[[1;5D' backward-word   # [Ctrl-LeftArrow]
bindkey '^H' backward-kill-word   # [Ctrl-Backspace]
bindkey '^?' backward-delete-char # [Backspace]
bindkey '^Z' undo                 # [Ctrl-Z]
bindkey '^Y' redo                 # [Ctrl-Y]
bindkey '^Q' push-line            # [Ctrl-Q]
bindkey '^A' vi-beginning-of-line # [Ctrl-A]
bindkey '^E' vi-end-of-line       # [Ctrl-E]
bindkey ' ' magic-space           # [Space] do history expansion

# from zsh-history-substring-search
bindkey '^[[A' history-substring-search-up    # [UpArrow]
bindkey '^[[B' history-substring-search-down  # [DownArrow]

# [Enter] clear screen if no input
# magic-enter() {
#     # Ref: https://superuser.com/questions/1389834
#     if [[ $BUFFER == '' ]]; then
#         local prompt_height=$(echo -n ${(%%)PS1} | wc -l)
#         local lines=$((LINES - prompt_height))
#         printf "$terminfo[cud1]%.0s" {1..$lines}  # cursor down
#         printf "$terminfo[cuu1]%.0s" {1..$lines}  # cursor up
#         zle reset-prompt
#     else
#         zle accept-line
#     fi
# }
# zle -N magic-enter
# bindkey '^M' magic-enter
# FIXME: highlight of zsh-autosuggestions is incorrect

# [Ctrl-R] search history by fzf-tab
fzf-history-search() {
    # Ref: https://github.com/Aloxaf/dotfiles/blob/0619025cb2/zsh/.config/zsh/snippets/key-bindings.zsh#L80-L102
    local selected=$(
        fc -rl 1 |
        ftb-tmux-popup -n '2..' --tiebreak=index --prompt='cmd> ' ${BUFFER:+-q$BUFFER}
    )
    if [[ $selected != '' ]]; then
        zle vi-fetch-history -n $selected
    fi
    zle reset-prompt
}
zle -N fzf-history-search
bindkey '^R' fzf-history-search

# [Ctrl-N] navigate by xplr
bindkey -s '^N' '^Q cd -- ${$(xplr):-.} \n'
# xplr-navigate() {
#     local dir=$(xplr)
#     if [[ $dir != '' ]]; then
#         cd -- $dir
#     fi
#     zle reset-prompt
# }
# zle -N xplr-navigate
# bindkey '^N' xplr-navigate
