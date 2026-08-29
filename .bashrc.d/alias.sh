if [[ "$(uname)" == "Darwin" ]]; then
    alias ls='ls -G'
    alias ll='command ls -lhG'
    alias la='command ls -AG'
    alias lla='command ls -AlhG'
else
    alias ls='ls --color=auto'
    alias ll='command ls -lh --color=auto'
    alias la='command ls -A --color=auto'
    alias lla='command ls -Alh --color=auto'
fi

alias gss='git status -s'
alias gst='git status'
alias gaa='git add -A'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcane='git commit --amend --no-edit'
alias gfe='git fetch'

alias tn='tmux new -s'
alias ta='tmux attach -t'
alias tl='tmux ls'
