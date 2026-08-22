# Scripts

`home/scripts.nix` wraps each of these into its own package and puts it on `PATH` after activation.

## `cli/`

These are shell commands meant to be run by hand.

- **`switch [switch|boot|test|build]`** - rebuild and apply the current machine's configuration. Picks `homeConfigurations.mac` on macOS, `nixosConfigurations.<hostname>` on NixOS, or `homeConfigurations.cli` on other Linux.
- **`cli-bootstrap [profile]`** - installs Nix if missing and applies a Home Manager profile (`mac` on macOS, `cli` on other Linux by default). Used for first-time setup on a new machine.
- **`template <name> [-d <dirname>]`** - scaffolds a `.nix` dev-shell from `../templates`, records its origin in `.nix/README.md`, then runs `direnv allow`. With `-d`, it first creates and initializes that directory; otherwise it uses the current directory.
- **`run`** - runs `$RUN_CMD` (set per-project via `.envrc`) from the direnv project root. Lets each template define its own "run the thing" command.
- **`theme`** - switches the system-wide color theme and reloads supported clients to match.
- **`get [path...]`** - copies files in. With no args, interactively fzf-picks from `$HOME` (or `$GET_BASE`) and copies selections into the current directory; with args, rsyncs the given paths in.
- **`open <file>`** - cross-platform `open`/`xdg-open` wrapper.
- **`yank`** - copies stdin to the system clipboard. Also used internally by `hf` and by mux's Vim mode.
- **`hf [query]`** - fuzzy-search zsh history (optionally pre-filtered) and yank the selected line.

## `internal/`

Not meant to be run directly - called by other tooling (the quickshell status bar).

- **`claude-usage`** / **`codex-usage`** - print current usage/rate-limit stats for the Claude and Codex CLIs as JSON.
