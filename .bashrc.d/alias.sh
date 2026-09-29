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

if command -v squeue >/dev/null 2>&1; then
    alias sq='squeue -u "$USER"'
fi
if command -v scontrol >/dev/null 2>&1; then
    alias sj='scontrol show job'
fi

if command -v condor_q >/dev/null 2>&1; then
    alias cq='condor_q "$USER"'
    alias cj='condor_q -long'
fi

alias untar='tar -xf'
alias tarls='tar -tf'
alias mktgz='tar -czf'
