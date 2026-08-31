# Scripts

`home/scripts.nix` makes a package for each script. The activation then puts each
package on `PATH`.

## The `cli/` directory

The user starts these commands manually.

### `switch [switch|boot|test|build]`

The `switch` command rebuilds the configuration of the current machine. The command
then applies the configuration. The command selects one of these targets:

- `homeConfigurations.mac` on macOS
- `nixosConfigurations.<hostname>` on NixOS
- `homeConfigurations.cli` on other Linux systems

### `cli-bootstrap [profile]`

The `cli-bootstrap` command installs Nix if Nix is not on the machine. The command
then applies a Home Manager profile. The default profile is `mac` on macOS. The
default profile is `cli` on other Linux systems. Use this command for the first
installation on a new machine.

### `template <name> [-d <dirname>]`

The `template` command copies a `.nix` development shell from the `../templates`
directory. The command writes the source of the template into `.nix/README.md`. The
command then runs `direnv allow`. The `-d` option makes the given directory first.
Without the `-d` option, the command uses the current directory.

### `run`

The `run` command starts the command in the `$RUN_CMD` variable. Each project sets
this variable in its `.envrc` file. The command starts in the root directory of the
direnv project.

### `theme`

The `theme` command changes the color theme of the system. The command then reloads
each supported client.

### `get [path...]`

The `get` command copies files into the current directory. Without an argument, the
command shows an fzf menu of the files in `$HOME`. The `$GET_BASE` variable can
replace `$HOME`. Select the files in the menu. The command then copies the files.
With an argument, the command copies the given paths with rsync.

### `open <file>`

The `open` command starts `open` on macOS. The command starts `xdg-open` on Linux.

### `yank`

The `yank` command copies the standard input to the clipboard of the system. The
command uses the OSC 52 terminal sequence for a copy through an SSH connection. The
`hf` command and the Vim mode of mux also use `yank`.

### `hf [query]`

The `hf` command searches the Zsh history with a fuzzy match. Give a query to limit
the results. Select a line. The command then copies the line to the clipboard.

## The `internal/` directory

Do not start these commands manually. Other software starts them. The quickshell
status bar is an example.

### `claude-usage` and `codex-usage`

These two commands print the current usage data and the rate-limit data. The
commands print the data in the JSON format. `claude-usage` reads the data of the
Claude CLI. `codex-usage` reads the data of the Codex CLI.
