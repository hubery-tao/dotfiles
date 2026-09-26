# dotfiles

Personal shell, tmux, and Neovim configuration for Linux and macOS.

## Install

Clone the repository into a permanent location, enter it, then run:

```sh
./setup.sh
```

For a server or another environment without a desktop, use:

```sh
./setup.sh --no-gui
```

`--no-gui` disables Markdown Preview and VimTeX's PDF viewer. LaTeX editing
and compilation, LSP, terminals, and other plugins remain enabled.

Use `./setup.sh --gui` to restore the full configuration. Restart Neovim after
switching profiles. The choice is saved per machine in
`${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/nvim-profile`, outside the repository.
Without a flag, setup preserves the saved choice (default: `gui`); it does not
detect SSH or display availability. Run `./setup.sh --help` for options.

If Markdown Preview was already installed, `:Lazy clean` can remove its unused
files after switching to `--no-gui` (review the cleanup list before confirming).

Setup creates **absolute symlinks** for `.tmux.conf`, the Neovim configuration,
executables in `.local/bin/`, and shell snippets. If you move this repository,
rerun setup from its new location. Existing targets are replaced only after
confirmation and backed up as `*.backup.*`; unchanged links are skipped.
Neovim uses `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`.

Shell snippets go into `~/.bashrc.d/` on Linux and `~/.zshrc.d/` on macOS.
Setup adds a loader to `.bashrc` or `.zshrc` once; on macOS it also configures
Ctrl-W to use Bash-style word boundaries. Open a new shell to load the changes.
Agent notification settings are merged into the agent configs; see below.

## Requirements

- Bash and Git
- Neovim 0.11 or newer
- tmux for `.tmux.conf`
- A Nerd Font for plugin icons (optional)
- Node.js/npm for Pyright (including `--no-gui`); Node.js also runs Copilot,
  and the GUI profile uses Node.js/npm for Markdown Preview
- `ripgrep` (`rg`) for Telescope live grep (`<leader>fg`)
- A C compiler (`cc`, `gcc`, or `clang`) for Treesitter parsers
- `codex` and `claude` on `PATH` for the agent workspace (optional)
- `python3` to merge the Claude Code hook, and to read notification detail
- `curl` for agent notifications (optional)
- A TeX distribution and `latexmk` for LaTeX compilation (optional)
- Skim on macOS or Zathura on Linux for VimTeX PDF viewing (optional, GUI profile)

`setup.sh` checks for Node.js/npm, ripgrep, and a C compiler at the end and
reports missing tools without installing them or failing setup. Install or load
missing tools so they are on `PATH` before starting Neovim.

On first launch, lazy.nvim installs plugins and Mason installs language servers;
allow these to finish before quitting. Use `nvim .` to open a project with the
file tree and a shell terminal, or `nvim file` to edit a file directly.

If a language server fails to install, open `:Mason` and `:MasonLog` for details.
For the Pyright “npm not found” error, make `node` and `npm` available on `PATH`,
restart Neovim, then run `:MasonInstall pyright`.

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
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Numbered shell terminals; agent panes use Neovim's native terminals |
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
| `<leader>y` / `<leader>Y` | Copy a motion or selection / the current line to the system clipboard |
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
the live prompt. Quitting Neovim stops its shell and agent sessions.
Clipboard copying uses OSC 52 and requires support in your local terminal.

## Agent notifications

`.local/bin/agent-notify` pushes a notification through [ntfy.sh](https://ntfy.sh)
when Codex or Claude Code finishes a turn or blocks on a permission prompt, so
a run started over SSH can be left unattended.

`setup.sh` asks once for a topic. Accept the generated topic or enter your own,
use it on each machine, and subscribe in the ntfy app. Topics allow 1–64 letters,
numbers, underscores, or dashes. Answer `skip` to leave notifications silent;
edit `~/.config/agent-notify/topic` to enable or change them later, or empty the
file to disable them.

Treat the topic as a password: anyone who knows it can read notifications.
Messages say only `Turn complete.` or `Waiting for approval.` by default. To
include agent output when available, create `~/.config/agent-notify/detail`
or set `AGENT_NOTIFY_DETAIL=1`. The file also works with existing tmux sessions.

Titles include the agent, project directory, and hostname. Set
`AGENT_NOTIFY_HOST` for a friendlier host label, or
`AGENT_NOTIFY_TOPIC` to override the topic file.

After installing or changing the Codex hook, open `/hooks` in the Codex CLI,
review the `agent-notify` command, and trust it -- Codex skips new or changed
hooks until they are trusted.
