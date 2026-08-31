# Templates

A template is a scaffold for a project. Start a template with the `template <name>
[-d <dirname>]` command. The `-d` option makes the given directory first. Without
the `-d` option, the command uses the current directory.

Each template supplies a `.nix` directory. This directory holds a `flake.nix` file.
This file declares all tools for the project. Thus the development environment is
declarative. The environment is also the same on each machine.

All templates use the same lock file. The central lock file is
`templates/.flake.lock`. The command copies this file to `.nix/flake.lock`.

Each template also supplies an `.envrc` file. direnv reads this file. direnv then
starts the environment when you go into the directory.

The `template <name>` command copies `templates/dev-readme.md` to `.nix/README.md`
in the new project. The command adds three items to the end of the file:

- The source
- The name of the template
- The date of the generation

Some templates supply a second `README.md` file in the root directory of the
project. The `arduino` template is an example. This file gives setup notes for that
template only. The command does not change this file.

## The available templates

- **`arduino`** — An Arduino project
- **`blank`** — An empty project
- **`c`** — A C project
- **`latex`** or **`tex`** — A LaTeX project
- **`python`** — A Python project
- **`pyts`** — A TypeScript project with Python
- **`rust`** — A Rust project
