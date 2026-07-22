# Welcome to my Nix

This is my Nix configuration for my NixOS desktop, macOS, and headless Linux environments.

## Why Nix

Nix manages packages and configuration declaratively. Instead of modifying a machine through a sequence of installation and configuration steps, Nix builds the full environment described by the configuration - including package versions and dependencies. The same declaration therefore always produces the exact same environment without depending on the machine’s previous state.

The configuration also documents the entire setup. Every managed package and setting is defined in this repository, making it easy to look up how something works, change it, or remove it cleanly.

## Bootstrapping

My Nix Home Manager CLI setup can be easily applied on any x86_64 Linux system (including WSL) with:

```sh
git clone https://g.any-0.com/nix.git ~/nix
cd ~/nix
./scripts/cli/cli-bootstrap
```

This installs Nix if it is missing and applies the `cli` profile.
The repository is expected at `~/nix`.

## Applying changes

After the initial activation, all scripts in `./scripts/` are on `PATH`. Rebuilds are done with:
```sh
switch
```
It picks the right target for the platform it runs on: `homeConfigurations.mac` on macOS, `nixosConfigurations.<hostname>` on NixOS, and `homeConfigurations.cli` on other Linux.

Dotfiles are symlinked out of the store from `./dotfiles/`, so edits to them take effect without a rebuild.

## Shell

Zsh is used as the primary shell with a custom prompt. When a direnv environment is active, its root directory is underlined in the path.

Local interactive shells automatically attach to an existing tmux session or create a new one. Tmux saves its session state at the start of every minute and restores it when a new tmux server starts.

## Templates

This repository also includes development templates, documented in [`templates/README.md`](templates/README.md).

A new project is started with:
```sh
template python
```
This initializes the template in the current directory, records where and when it was generated in `.nix/README.md`, and runs `direnv allow`.
