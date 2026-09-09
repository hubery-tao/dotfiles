# dotfiles

Personal shell, tmux, and Neovim configuration for Linux and macOS.

## Install

Clone the repository, then run:

```sh
./setup.sh
```

Every path in this repository mirrors its destination under `$HOME`:
`.config/nvim/` is linked to `~/.config/nvim/`, `.local/bin/` to
`~/.local/bin/`, and so on. Keep new files on that pattern -- it is what makes
the destination of anything here obvious from its path alone.

The installer creates symbolic links into the current user's home directory. If
a target already exists, it asks before replacing it. Replaced files and
directories are moved to a timestamped `*.backup.*` path instead of being
deleted. Running the installer again does not duplicate shell startup entries.

## Requirements

- Bash and Git
- Neovim 0.11 or newer
- tmux for `.tmux.conf`
- A Nerd Font for plugin icons (optional)
- Node.js/npm for Markdown Preview
- Skim on macOS or Zathura on Linux for VimTeX PDF viewing (optional)

Neovim plugins are installed automatically by lazy.nvim. Language servers are
installed through Mason when Neovim starts.

## Neovim key bindings

`<leader>` is Space and `<localleader>` is comma.

| Keys | Action |
| --- | --- |
| `<leader>ff/fg/fb/fh/fr` | Telescope files, grep, buffers, help, and resume |
| `<leader>t` / `2<leader>t` | Focus terminal 1 / terminal 2 |
| `<leader>e` / `2<leader>e` | Focus editor window 1 / editor window 2 |
| `<leader>c` / `<leader>a` | Focus or open the Codex / Claude Code workspace (they share the right-hand pane; the hidden one keeps running) |
| `<leader>=` | Restore all workspace windows to their default sizes |
| `<leader>o` | Focus or open the file tree |
| `<leader>y` | Copy to the system clipboard |
| `<A-,>` / `<A-.>` | Go to the previous / next buffer |
| `<A-1>` … `<A-9>` / `<A-0>` | Go to a numbered / the last buffer |
| `<A-c>` | Close the current buffer, prompting for unsaved changes |
| `<C-j>` / `<C-l>` in Insert mode | Accept a full Copilot suggestion / one suggestion line |
| `<C-Space>` in Terminal mode | Return to Normal mode |
| `[[` / `]]` in a terminal's Normal mode | Jump to the previous / next shell command |

After inspecting earlier terminal output, press `G` and then `i` to return to
the live prompt. Prompt navigation requires Neovim 0.11 or newer and is enabled
automatically for shells started inside Neovim.

## Agent notifications

`.local/bin/agent-notify` pushes a notification when Codex or Claude Code finishes a
turn or blocks on a permission prompt, so a run started over SSH can be left
unattended. It posts to [ntfy.sh](https://ntfy.sh) rather than emitting a
terminal escape sequence: inside `ssh -> tmux -> nvim -> :terminal` there is no
escape sequence that survives the trip, since tmux 2.7 predates
`allow-passthrough` and drops any OSC it does not recognize.

`setup.sh` wires this up. It asks once for an ntfy topic -- press Enter to take
the generated suggestion on the first machine, then enter that same topic on
every other machine, and subscribe to it in the ntfy app. Answer `skip` to
leave notifications silent; the resulting empty topic file remembers that
choice, and writing a topic into it enables notifications later. Topic names
may contain only letters, numbers, underscores, and dashes, up to 64 characters.
The topic is a shared secret, so it is stored in
`~/.config/agent-notify/topic` rather than in this repository, and
`AGENT_NOTIFY_TOPIC` overrides it. Without a topic the script exits quietly.

Every machine posts to that one topic, so a single subscription catches every
run wherever it was started. Each notification is titled with the agent, the
project directory and the host name -- `codex finished in STAR (isye-hps0401)`
-- which is what tells two machines apart; set `AGENT_NOTIFY_HOST` to use a
friendlier label than the host name. Give a machine its own topic instead only
if its notifications need to be muted separately.

An ntfy.sh topic has no access control -- the documentation calls the topic
"essentially a password", and anyone holding it can read the whole history --
so the notification body carries no payload text by default: it says only
`Turn complete.` or `Waiting for approval.`. To send the agent's own words
instead (Codex reports its last reply, Claude Code the reason it is blocked),
opt the machine in with `AGENT_NOTIFY_DETAIL=1` or by creating
`~/.config/agent-notify/detail`. Prefer the file: a hook inherits its
environment from whichever shell started the agent, by way of a tmux server
that may predate the export. The title still names the agent, the project
directory and the host on every machine.

The agent configs are merged into rather than symlinked, because the tools
rewrite them (Claude Code stores the theme and model chosen through `/config`,
Codex appends a `trust_level` table per project) and they hold machine-specific
absolute paths. `setup.sh` adds `Stop` and `Notification` hooks to
`~/.claude/settings.json`, and `notify` plus a `PermissionRequest` hook to
`~/.codex/config.toml`, leaving every other key alone and doing nothing on a
second run. The `Notification` hook carries a matcher because that event also
fires on a 60-second idle timer, which would otherwise send a second
notification after every single turn. Codex runs the `PermissionRequest` hook
in the background so a slow network cannot delay the approval prompt, and it
coexists with any other hooks already configured for that event. After
installing or changing the Codex hook, open `/hooks` in the Codex CLI, review
the `agent-notify` command, and trust it; Codex skips new or changed unmanaged
hooks until they are trusted. Merging the Claude config needs `python3`; the
Codex config does not.

## Update plugins

Run `:Lazy update` inside Neovim. `lazy-lock.json` is intentionally ignored so
each installation resolves the configured plugin versions independently.
