{
  description = "Python project";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        (python312.withPackages (ps: [ ps.tkinter ]))
        ruff
      ];

      shellHook = ''
        if [ ! -d .venv ]; then
          python3 -m venv .venv --system-site-packages
        fi
        source .venv/bin/activate

        export MPLCONFIGDIR="$PWD/.venv/matplotlib"
        mkdir -p "$MPLCONFIGDIR"
        if [ ! -f "$MPLCONFIGDIR/matplotlibrc" ]; then
          printf 'backend: TkAgg\nbackend_fallback: False\n' > "$MPLCONFIGDIR/matplotlibrc"
        fi
      '';

      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
      ];
    };
  };
}
