# The development environment

You do not install the development tools manually. [Nix](https://nixos.org/) builds
the environment from `.nix/flake.nix`. The `.nix/flake.lock` file records the
version of each tool.

Nix makes the same environment on Linux, on macOS, and on Windows with the Windows
Subsystem for Linux (WSL). Install Nix first.

[direnv](https://direnv.net/) starts the environment automatically. direnv does
this when you go into this directory.

## How to change the tools

To add a package or to change a tool, do these steps:

1. Edit `.nix/flake.nix`.
2. Run `direnv reload`.

## How to update the versions

The `.nix/flake.lock` file holds the version of each package. To get newer
versions, run `nix flake update` in the `.nix/` directory.
