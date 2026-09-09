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

mkdir -p "$HOME/.local/bin"
for script in "$curr_dir"/.local/bin/*; do
    [[ -f "$script" && -x "$script" ]] || continue
    link_config "$script" "$HOME/.local/bin/${script##*/}"
done

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

# Agent notification wiring.
#
# The agent configs are merged into rather than symlinked: both files are owned
# and rewritten by the tools themselves (Claude Code stores the theme and model
# chosen through /config, Codex appends a trust_level table per project), and
# both hold absolute paths that differ between machines. Only the notification
# wiring belongs to this repository, so each step below is idempotent and
# leaves every other key alone.

agent_notify_bin="$HOME/.local/bin/agent-notify"
agent_notify_topic_file="$HOME/.config/agent-notify/topic"

setup_notify_topic() {
    local suggestion reply saved_topic

    if [[ -e "$agent_notify_topic_file" ]]; then
        if [[ -s "$agent_notify_topic_file" ]]; then
            IFS= read -r saved_topic < "$agent_notify_topic_file" || true
            if [[ $saved_topic =~ ^[-_A-Za-z0-9]{1,64}$ ]]; then
                printf 'Notification topic already set: %s\n' "$agent_notify_topic_file"
                return 0
            fi
            printf 'Invalid ntfy topic in %s; enter a replacement\n' \
                "$agent_notify_topic_file" >&2
        else
            printf 'Agent notifications already skipped on this machine\n'
            return 0
        fi
    fi

    # Anyone who knows the topic can read the notifications, so it stays out of
    # the repository and is entered once per machine.
    suggestion="agent-$(openssl rand -hex 8 2>/dev/null || date +%s)"

    while true; do
        printf '\nAgent notifications are delivered through an ntfy.sh topic.\n'
        printf 'Use the same topic on every machine, and subscribe to it in the ntfy app.\n'
        printf 'Topic [%s], or "skip": ' "$suggestion"

        if ! IFS= read -r reply; then
            printf '\n'
            return 0
        fi

        case "$reply" in
            skip|SKIP)
                # An empty file remembers this choice without inventing a second
                # piece of state. Writing a topic into it enables notifications.
                mkdir -p "$(dirname -- "$agent_notify_topic_file")"
                : > "$agent_notify_topic_file"
                chmod 600 "$agent_notify_topic_file"
                printf 'Skipped: no topic, so notifications stay silent on this machine\n'
                return 0
                ;;
            "") reply=$suggestion ;;
        esac

        if [[ $reply =~ ^[-_A-Za-z0-9]{1,64}$ ]]; then
            break
        fi
        printf 'Invalid ntfy topic: use 1-64 letters, numbers, underscores, or dashes\n' >&2
    done

    mkdir -p "$(dirname -- "$agent_notify_topic_file")"
    printf '%s\n' "$reply" > "$agent_notify_topic_file"
    chmod 600 "$agent_notify_topic_file"
    printf 'Subscribe to this topic in the ntfy app: %s\n' "$reply"
}

codex_permission_notify_present() {
    local config=$1

    # Look for our command inside a PermissionRequest handler. Merely finding
    # another handler for the same event must not suppress this one: Codex
    # supports multiple matcher groups and runs all matching hooks.
    awk '
        /^[[:space:]]*\[/ {
            in_handler = ($0 ~ /^[[:space:]]*\[\[hooks[.]PermissionRequest[.]hooks\]\][[:space:]]*(#.*)?$/)
            next
        }
        in_handler && /^[[:space:]]*command[[:space:]]*=/ &&
            /agent-notify[[:space:]]+codex[[:space:]]+waiting/ {
            found = 1
        }
        END { exit found ? 0 : 1 }
    ' "$config"
}

merge_claude_hooks() {
    local settings="$HOME/.claude/settings.json"

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'Skipped Claude Code hooks: python3 is required to merge %s\n' "$settings" >&2
        return 0
    fi

    python3 - "$settings" "$agent_notify_bin" <<'PY'
import json, os, sys

path, notify = sys.argv[1], sys.argv[2]

try:
    with open(path) as handle:
        settings = json.load(handle)
except FileNotFoundError:
    settings = {}
except ValueError:
    print(f"Skipped Claude Code hooks: {path} is not valid JSON")
    raise SystemExit(0)

hooks = settings.setdefault("hooks", {})
added = False

# Stop fires when a turn ends. Notification covers several triggers, and its
# matcher is tested against notification_type, so it is narrowed to the ones
# that actually block on the user: without this, "idle_prompt" fires 60s after
# every turn and doubles each notification.
NEEDS_USER = "permission_prompt|worker_permission_prompt|agent_needs_input"

for event, event_arg, matcher in (
    ("Stop", "done", None),
    ("Notification", "waiting", NEEDS_USER),
):
    groups = hooks.setdefault(event, [])
    if any("agent-notify" in hook.get("command", "")
           for group in groups for hook in group.get("hooks", [])):
        continue
    group = {} if matcher is None else {"matcher": matcher}
    group["hooks"] = [{
        "type": "command",
        "command": f'"{notify}" claude {event_arg}',
        "async": True,
        "timeout": 10,
    }]
    groups.append(group)
    added = True

if not added:
    print(f"Claude Code notification hooks already present: {path}")
    raise SystemExit(0)

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as handle:
    json.dump(settings, handle, indent=2)
    handle.write("\n")
print(f"Added Claude Code notification hooks: {path}")
PY
}

merge_codex_hooks() {
    local config="$HOME/.codex/config.toml"
    local added=0
    local notify_line

    mkdir -p "$HOME/.codex"
    [[ -e "$config" ]] || : > "$config"

    # `notify` is a root key, so it must occur before the first table header.
    # Inspect only that key: the PermissionRequest command also contains the
    # text "agent-notify" and must not make a custom notify look like ours.
    notify_line=$(awk '
        /^[[:space:]]*\[/ { exit }
        /^[[:space:]]*notify[[:space:]]*=/ { print; exit }
    ' "$config")
    if [[ -n $notify_line ]]; then
        [[ $notify_line == *agent-notify* ]] \
            || printf 'Codex already sets `notify` in %s; left alone\n' "$config" >&2
    else
        printf 'notify = ["%s", "codex", "done"]\n' "$agent_notify_bin" \
            | cat - "$config" > "$config.dotfiles-tmp"
        mv "$config.dotfiles-tmp" "$config"
        added=1
    fi

    if ! codex_permission_notify_present "$config"; then
        {
            # A second [hooks] header would be a duplicate-table error.
            grep -Eq '^[[:space:]]*\[hooks\]' "$config" || printf '\n[hooks]\n'
            printf '[[hooks.PermissionRequest]]\n'
            printf '[[hooks.PermissionRequest.hooks]]\n'
            printf 'type = "command"\n'
            # Codex rejects an array here; the command must be a single string.
            printf 'command = "%s codex waiting"\n' "$agent_notify_bin"
            # This hook only sends a notification; it never makes an approval
            # decision, so it should not delay the permission prompt.
            printf 'async = true\n'
            printf 'timeout = 10\n'
        } >> "$config"
        added=1
    fi

    if (( added )); then
        printf 'Added Codex notification hooks: %s\n' "$config"
    else
        printf 'Codex notification hooks already present: %s\n' "$config"
    fi
}

setup_notify_topic
merge_claude_hooks
merge_codex_hooks
