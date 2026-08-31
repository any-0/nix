# Nix Configuration

This repository holds the Nix configuration for three environments:

- A NixOS desktop
- macOS
- Headless Linux

## Why the setup uses Nix

Nix installs packages and applies settings from a declaration. You do not change a
machine with a sequence of manual steps. Nix builds the full environment that the
declaration specifies. The environment includes each package version and each
dependency.

The same declaration always makes the same environment. The previous condition of
the machine has no effect on the result.

The declaration is also the documentation of the setup. This repository contains
each managed package and each setting. You can do these tasks:

- Find how a component operates
- Change a component
- Remove a component fully

## Features

The default shell is Zsh. Zsh starts in mux, a terminal multiplexer. Mux uses
`Alt` + `a` as the leader key. These two keys follow the leader key:

- `Alt` + `s` opens the session tree.
- `Alt` + `w` starts the Vim mode.

The mux daemon holds the pseudo-terminals (PTY). The daemon writes pane output and
layout changes to a journal. Sessions and scrollback come back after a daemon
restart or a machine restart.

The Zsh prompt is minimal. The prompt shows the git state, the jj state, and the
direnv state.

A development environment usually uses jj with a colocated git repository. The
environment has a `.nix` directory. This directory holds a flake. The flake
declares the development shell for that project. An `.envrc` file in the root
directory starts the flake.

The `theme` command sets the colors of the command-line interface (CLI). Define a
theme in `dotfiles/themes/palettes.nix`. These programs use the theme:

- eza
- jj
- kitty
- neovim
- opencode

## Tools

### mux

Mux is a small terminal multiplexer. The mux daemon holds the CLI processes. The
terminal emulator does not hold them. The processes continue when the terminal
closes. The processes also continue when the SSH connection stops.

Mux supplies these functions:

- Sessions
- Windows
- Panes
- A session tree
- A Vim mode

Use the Vim mode to do these tasks in the scrollback:

- Move the cursor
- Find text
- Copy text

### jj in place of git

This setup uses [jj](https://github.com/jj-vcs/jj) in place of git.

jj removes the necessity for HEAD. The working copy is always a commit. Thus you
move to a different change with one command: `jj edit abc`.

jj makes bookmark control easy. The command `jj bookmark set master -r abc` puts
the tip of the `master` bookmark at commit `abc`.

The command `jj undo` reverses each jj command.

jj is compatible with git. jj operates with all git repositories and with all git
remotes. Colocation keeps the `.git/` directory correct. Each git tool continues to
operate correctly.

### zoxide in place of `cd`

An alias makes `cd` start zoxide. Give a part of a directory name to `cd`. zoxide
then goes to the matching directory that you use most frequently. For example, `cd
toJPG` goes to `~/dev/project123/assets/images/toJPG` from any directory.

`cd` operates as usual when you give a full path.

### eza in place of `ls`

eza is a replacement for `ls`. eza shows an icon for each file. A Nerd Font is
necessary to show the icons correctly.

### kitty

The terminal emulator is [kitty](https://sw.kovidgoyal.net/kitty/). The
configuration sets a fast smear cursor. The font is [IosevkaTermSlab Nerd
Font](https://www.nerdfonts.com/font-downloads). On macOS, kitty makes the left
Option key operate as the Alt key.

### Neovim

The Neovim configuration is small. Neovim is the editor for files. The
configuration sets up the Language Server Protocol (LSP), treesitter, and nvim-cmp
for the necessary languages.

The key bindings stay near the Neovim defaults. Some small changes adapt the
default layout from QWERTY to QWERTZ. The
[vim-easymotion](https://github.com/easymotion/vim-easymotion) plugin moves the
cursor quickly.

## First installation

You can apply the Home Manager setup for the CLI on these systems:

- An x86_64 Linux system, which includes the Windows Subsystem for Linux (WSL)
- An AArch64 macOS system

To install the setup, do these steps:

1. Clone the repository into `~/nix`:

   ```sh
   git clone https://g.any-0.com/nix.git ~/nix
   ```

2. Go into the repository:

   ```sh
   cd ~/nix
   ```

3. Start the bootstrap script:

   ```sh
   ./scripts/cli/cli-bootstrap
   ```

The script installs Nix if Nix is not on the machine. The script then applies a
profile. The script applies the `cli` profile on x86_64 Linux. The script applies
the `mac` profile on AArch64 macOS.

The scripts expect the repository in `~/nix`.

## How to apply changes

After the first installation, all scripts in `./scripts/` are on `PATH`.

To rebuild the configuration, run this command:

```sh
switch
```

The `switch` script finds the correct target for the platform:

- On macOS, the target is `homeConfigurations.mac`.
- On NixOS, the target is `nixosConfigurations.<hostname>`.
- On other Linux systems, the target is `homeConfigurations.cli`.

Symbolic links connect the files in `./dotfiles/` to the home directory. The links
do not go through the Nix store. Thus a change to a dotfile becomes effective
immediately. A rebuild is not necessary.

## Templates

This repository also contains development templates.
[`templates/README.md`](templates/README.md) gives the documentation for the
templates.

To make a new project, run this command:

```sh
template python -d my-python-project
```

The command does these steps:

1. It makes the `my-python-project` directory.
2. It puts the template in that directory.
3. It writes the source and the date into `.nix/README.md`.
4. It runs `direnv allow`.

Do not give the `-d <dirname>` option if you want to use the current directory.

## Technical names and technical verbs

ASD-STE100 permits words that are not in the dictionary when they are technical
names (Rule 1.4) or technical verbs (Rule 1.5). This documentation uses these
words:

commit, dependency, direnv, dotfile, eza, flake, fzf, git, jj, kitty, macOS, mux,
Neovim, Nix, NixOS, pane, profile, repository, scrollback, session, shell,
symbolic link, template, zoxide, Zsh
