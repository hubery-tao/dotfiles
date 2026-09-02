# dotfiles

Personal shell, tmux, and Neovim configuration for Linux and macOS.

## Install

Clone the repository, then run:

```sh
./setup.sh
```

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

## Update plugins

Run `:Lazy update` inside Neovim. `lazy-lock.json` is intentionally ignored so
each installation resolves the configured plugin versions independently.
