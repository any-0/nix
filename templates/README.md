# Templates

Project scaffolds started with `template <name>`. Each template provides a `.nix` directory holding a `flake.nix` with all tooling needed for the project, so the dev environment is fully declarative and reproducible. All templates pin the same lock, kept centrally at `templates/.flake.lock` and copied into `.nix/flake.lock` on init. An `.envrc` is included to activate the environment with `direnv` on entering the directory.

Running `template <name>` copies `templates/dev-readme.md` into the new project as `.nix/README.md`, appended with its source, template name, and generation date.

Some templates also ship their own project-root `README.md` (e.g. `arduino`) with setup notes specific to that template; that file is separate and isn't touched when the dev-environment README is generated.

## Available templates

- **`arduino`** — Arduino project
- **`blank`** — Blank project
- **`c`** — C project
- **`latex`** / **`tex`** — LaTeX project
- **`python`** — Python project
- **`pyts`** — TypeScript + Python project
- **`rust`** — Rust project
