# Welcome to my Nix config

This is my Nix configuration for my NixOS desktop, macOS, and headless Linux environments.

## Why Nix

Nix manages packages and configuration declaratively. Instead of modifying a machine through a sequence of installation and configuration steps, Nix builds the full environment described by the configuration - including package versions and dependencies. The same declaration therefore always produces the exact same environment without depending on the machine's previous state.

The configuration also documents the entire setup. Every managed package and setting is defined in this repository, making it easy to look up how something works, change it, or remove it cleanly.

## Features

I use tmux heavily, so it starts by default in Zsh. I use `Alt` + `a` as the leader, with `Alt` + `s` opening the session tree and `Alt` + `w` starting copy mode. Tmux saves its session state at the start of every minute and restores it when a new tmux server starts, so all of my pane histories persist until the lines leave scrollback or I kill that pane. My tmux includes a top bar that changes color based on the tmux mode, to make things like copy mode more readable.

I use Zsh as my shell, with a minimal prompt that gives me info about the git/jj state and if I am in a direnv.

My development environments usually use jj with colocated git, and include a `.nix` directory with a flake that declares that project's dev shell. The flake is activated with a root-level `.envrc`.

The color scheme of the CLI can be configured using the `theme` command. Themes can be defined in `dotfiles/themes/palettes.nix` and get applied to eza, jj, kitty, neovim, and tmux.

## Tools

**tmux**

In tmux, all CLI processes are owned by the tmux server instead of the terminal emulator. That keeps everything running even when the terminal is closed or an SSH connection is lost. Tmux also has sessions, windows, and panes, making it easy to run many shells at the same time. Switching between sessions and windows is very fast and lightweight. I also heavily use its copy mode to scroll/search the current buffer and copy from it.

**jj instead of git**

I use [jj](https://github.com/jj-vcs/jj) instead of git. It completely removes the need for HEAD: the working copy is automatically a commit, so going back and forth between changes is as easy as `jj edit abc`. Branch management is way easier - just `jj bookmark set master -r abc` and the tip of the master branch is commit `abc`. Every jj command can be easily rolled back with `jj undo`. jj is fully git-compatible and interacts with any git repositories and remotes seamlessly. Using colocation, it keeps the `.git/` folder in sync, so anything that interacts with git does so completely normally.

**zoxide instead of `cd`**

With zoxide aliased to `cd`, a bare substring jumps to the most frequently visited matching directory: from anywhere, `cd toJPG` lands in `~/dev/project123/assets/images/toJPG`. Real paths still behave like normal `cd`.

**eza instead of `ls`**

Eza is a replacement for `ls` that provides file icons. The icons need a Nerd Font to render.

**kitty**

I use [kitty](https://sw.kovidgoyal.net/kitty/) as my terminal emulator. I have a fast smear cursor configured and use [IosevkaTermSlab Nerd Font](https://www.nerdfonts.com/font-downloads) as my font. On macOS, kitty configures the left Option key to be used as Alt.

**Neovim**

I use a light Neovim config for file editing. LSP, treesitter, and nvim-cmp are configured for the languages I use. My keybinds are kept very default on purpose, with some minor changes to adapt the default layout from QWERTY to QWERTZ. I use [vim-easymotion](https://github.com/easymotion/vim-easymotion) to move my cursor more effectively.

## Bootstrapping

My Nix Home Manager CLI setup can be applied on any x86_64 Linux system (including WSL) and on AArch64 macOS with:

```sh
git clone https://g.any-0.com/nix.git ~/nix
cd ~/nix
./scripts/cli/cli-bootstrap
```

This installs Nix if it is missing and applies the `cli` profile on x86_64 Linux and `mac` on AArch64 macOS.
The repository is expected at `~/nix`.

## Applying changes

After the initial activation, all scripts in `./scripts/` are on `PATH`. Rebuilds are done with:
```sh
switch
```
It picks the right target for the platform it runs on: `homeConfigurations.mac` on macOS, `nixosConfigurations.<hostname>` on NixOS, and `homeConfigurations.cli` on other Linux.

Dotfiles are symlinked out of the store from `./dotfiles/`, so edits to them take effect without a rebuild.

## Templates

This repository also includes development templates, documented in [`templates/README.md`](templates/README.md).

A new project is started with:
```sh
template python
```
This initializes the template in the current directory, records where and when it was generated in `.nix/README.md`, and runs `direnv allow`.
