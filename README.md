# Welcome to my Nix

This is my Nix configuration for my NixOS desktop, macOS, and headless Linux environments.

The repository is expected at `~/nix`.

Dotfiles are symlinked out of the store from `./dotfiles/`, so edits to them take effect without a rebuild.

My Nix Home Manager CLI setup can be easily applied on any x86_64 linux system (including WSL) with:
```sh
git clone https://g.any-0.com/nix.git ~/nix
cd ~/nix
./scripts/cli-bootstrap
```
This installs Nix if it is missing and applies the `cli` profile.

## Applying changes

After the initial activation, all scripts in `./scripts/` are on `PATH`. Rebuilds are done with:
```sh
switch
```
It picks the right target for the platform it runs on: `homeConfigurations.mac` on macOS, `nixosConfigurations.<hostname>` on NixOS, and `homeConfigurations.cli` on other Linux.

## Shell

Zsh is used as the primary shell with a custom prompt:

```text
julian@pc  ~/dev/pythonProject  +39 -0
❯
```

When a direnv environment is active, its root directory is underlined in the path.

Local interactive shells automatically attach to an existing tmux session or create a new one. Tmux saves its session state at the start of every minute and restores it when a new tmux server starts.

## Templates

This repository also includes development templates. The way my templates are set up is that there is a `.dev` directory that stores a `flake.nix` with all required tooling for development, thus making it trivial to recreate the environment. All templates share a `flake.lock`. The templates also include a `.envrc` to instantly activate the environment using `direnv` when the directory is entered.

A new project is started with:
```sh
template python
```
This initializes the template in the current directory, stamps the template name and repository revision into `.dev/flake.nix`, and runs `direnv allow`. Available templates are `arduino`, `blank`, `c`, `latex`/`tex`, `python`, `pyts`, and `rust`.
