# Mark prompts created inside Neovim terminals. Neovim 0.11+ uses these
# OSC 133 markers to make [[ and ]] jump between shell prompts.
if [[ -n ${NVIM:-} ]]; then
    __dotfiles_nvim_prompt_mark() {
        printf '\033]133;A\007'
    }

    if [[ -n ${BASH_VERSION:-} ]]; then
        if [[ ${PROMPT_COMMAND:-} != *"__dotfiles_nvim_prompt_mark"* ]]; then
            if declare -p PROMPT_COMMAND 2>/dev/null | grep -q '^declare -a'; then
                PROMPT_COMMAND=(__dotfiles_nvim_prompt_mark "${PROMPT_COMMAND[@]}")
            else
                PROMPT_COMMAND="__dotfiles_nvim_prompt_mark${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
            fi
        fi
    elif [[ -n ${ZSH_VERSION:-} ]]; then
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd __dotfiles_nvim_prompt_mark
    fi
fi
