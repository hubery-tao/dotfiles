# dotfiles

Personal shell, tmux, and Neovim configuration for Linux and macOS.

## Install

Clone the repository, then run:

```sh
./setup.sh
```

The installer symlinks every path in this repository to the matching path under
`$HOME`: `.config/nvim/` to `~/.config/nvim/`, `.local/bin/` to
`~/.local/bin/`, and so on. If a target already exists it asks before replacing
it, and moves the old file to a timestamped `*.backup.*` path. Running it again
is safe.

The shell snippets are the one exception to the matching-path rule.
`.bashrc.d/` is linked into `~/.bashrc.d/` on Linux and `~/.zshrc.d/` on
macOS, and the installer appends a block to the shell profile it finds there
-- `~/.bashrc` or `~/.zshrc` -- that sources every `*.sh` in that directory.
On macOS it also appends `select-word-style bash`, so that zsh's `Ctrl-W`
stops at the same word boundaries bash uses. Both blocks sit between marker
comments, are added only once, and leave the rest of the profile alone.

## Requirements

- Bash and Git
- Neovim 0.11 or newer
- tmux for `.tmux.conf`
- A Nerd Font for plugin icons (optional)
- Node.js/npm for Markdown Preview
- `codex` and `claude` on `PATH` for the agent workspace (optional)
- `python3` to merge the Claude Code hook, and to read notification detail
- Skim on macOS or Zathura on Linux for VimTeX PDF viewing (optional)

Neovim plugins install themselves through lazy.nvim on first start, and
language servers through Mason.

## Neovim plugins

| Plugin | What it gives you |
| --- | --- |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager; `:Lazy` opens it |
| [tinted-nvim](https://github.com/tinted-theming/tinted-nvim) | Colour scheme (base24 kanagawa-dragon) |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line, plus the numbered buffer line at the top |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | File tree sidebar |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder for files, grep, buffers, and help |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting for C, Fortran, Lua, Markdown, Python, and Vim |
| [mason.nvim](https://github.com/mason-org/mason.nvim) + [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP; installs pyright, ruff, lua_ls, clangd, texlab, marksman, and fortls |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Completion, with friendly-snippets |
| [copilot.vim](https://github.com/github/copilot.vim) | GitHub Copilot suggestions; run `:Copilot setup` once |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git signs in the gutter and hunk navigation |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | Add, change, and delete surrounding pairs |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-closes brackets and quotes |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | The built-in terminals and the agent workspace |
| [vimtex](https://github.com/lervag/vimtex) | LaTeX editing and PDF viewing |
| [quarto-nvim](https://github.com/quarto-dev/quarto-nvim) | Quarto documents, with otter.nvim for embedded code |
| [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | Live Markdown preview in the browser |

Run `:Lazy update` to update them. `lazy-lock.json` is ignored, so every
machine resolves plugin versions independently.

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
| `[[` / `]]` in a terminal's Normal mode | Jump to the previous / next shell command (needs `.bashrc.d/nvim-terminal.sh`, so bash or zsh) |
| `gf` / `gF` in a terminal or agent pane | Open the path under the cursor in an editor window |
| `]c` / `[c` | Jump to the next / previous git hunk |
| `<localleader>mm/ms/mt` in Markdown | Start / stop / toggle the Markdown preview |
| `<Esc><Esc>` | Clear search highlighting |

After inspecting earlier terminal output, press `G` and then `i` to return to
the live prompt.

## Agent notifications

`.local/bin/agent-notify` pushes a notification through [ntfy.sh](https://ntfy.sh)
when Codex or Claude Code finishes a turn or blocks on a permission prompt, so
a run started over SSH can be left unattended.

`setup.sh` wires it up and asks once for a topic. Press Enter to take the
generated suggestion on the first machine, enter that same topic on every other
machine, and subscribe to it in the ntfy app -- one subscription then catches
every run wherever it was started. Answer `skip` to leave notifications silent;
writing a topic into `~/.config/agent-notify/topic` enables them later. Topic
names may use letters, numbers, underscores, and dashes, up to 64 characters.

Anyone who knows the topic can read its whole history, so treat it as a
password and keep it out of the repository. For that reason the notification
body says only `Turn complete.` or `Waiting for approval.` by default. To send
the agent's own words instead, create `~/.config/agent-notify/detail` on that
machine (or set `AGENT_NOTIFY_DETAIL=1`; the file is more reliable, since hooks
inherit their environment from a tmux server that may predate the export).

Each notification is titled with the agent, the project directory, and the host
name -- `Codex finished in STAR (isye-hps0401)` -- which is what tells two
machines apart. Set `AGENT_NOTIFY_HOST` for a friendlier label, or
`AGENT_NOTIFY_TOPIC` to override the topic file.

After installing or changing the Codex hook, open `/hooks` in the Codex CLI,
review the `agent-notify` command, and trust it -- Codex skips new or changed
hooks until they are trusted.
