#!/usr/bin/env bash

set -euo pipefail

system=$(uname -s)
case "$system" in
    Darwin)
        shellrc="$HOME/.zshrc"
        shellrcd_name=".zshrc.d"
        ;;
    Linux)
        shellrc="$HOME/.bashrc"
        shellrcd_name=".bashrc.d"
        ;;
    *)
        printf 'Error: unsupported operating system: %s\n' "$system" >&2
        exit 1
        ;;
esac

curr_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
shellrcd="$HOME/$shellrcd_name"

confirm_replace() {
    local target=$1
    local reply

    printf '%s already exists. Replace it with the dotfiles version? [y/N] ' "$target"
    if ! IFS= read -r reply; then
        printf '\n'
        return 1
    fi

    case "$reply" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

next_backup_name() {
    local target=$1
    local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
    local suffix=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${target}.backup.$(date +%Y%m%d-%H%M%S).${suffix}"
        ((suffix += 1))
    done

    printf '%s\n' "$backup"
}

link_config() {
    local source=$1
    local target=$2
    local backup

    if [[ -L "$target" && $(readlink "$target") == "$source" ]]; then
        printf 'Already linked: %s\n' "$target"
        return 0
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        if ! confirm_replace "$target"; then
            printf 'Skipped: %s\n' "$target"
            return 0
        fi

        backup=$(next_backup_name "$target")
        mv "$target" "$backup"
        printf 'Backed up existing config to %s\n' "$backup"
    fi

    ln -s "$source" "$target"
    printf 'Linked: %s -> %s\n' "$target" "$source"
}

link_config "$curr_dir/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$shellrcd"
for script in "$curr_dir"/.bashrc.d/*.sh; do
    [[ -e "$script" ]] || continue
    link_config "$script" "$shellrcd/${script##*/}"
done

touch "$shellrc"
shell_marker="# >>> dotfiles shell snippets >>>"
legacy_shell_line="if [ -d ~/$shellrcd_name ]; then"
if ! grep -Fq "$shell_marker" "$shellrc" && ! grep -Fq "$legacy_shell_line" "$shellrc"; then
    {
        printf '\n%s\n' "$shell_marker"
        printf 'if [ -d "$HOME/%s" ]; then\n' "$shellrcd_name"
        printf '    for file in "$HOME/%s"/*.sh; do\n' "$shellrcd_name"
        printf '        [ -e "$file" ] || continue\n'
        printf '        source "$file"\n'
        printf '    done\n'
        printf 'fi\n'
        printf '%s\n' "# <<< dotfiles shell snippets <<<"
    } >> "$shellrc"
    printf 'Updated shell configuration: %s\n' "$shellrc"
else
    printf 'Shell configuration already loads %s\n' "$shellrcd"
fi

if [[ $system == "Darwin" ]] && ! grep -Fq "autoload -Uz select-word-style" "$shellrc"; then
    {
        printf '\n%s\n' "# >>> dotfiles macOS word style >>>"
        printf '%s\n' "autoload -Uz select-word-style"
        printf '%s\n' "select-word-style bash"
        printf '%s\n' "# <<< dotfiles macOS word style <<<"
    } >> "$shellrc"
fi

mkdir -p "$HOME/.config"
link_config "$curr_dir/.config/nvim" "$HOME/.config/nvim"
