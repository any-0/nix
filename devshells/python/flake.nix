{
  description = "Shared Python dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    mk = system:
      let pkgs = import nixpkgs { inherit system; };
      in pkgs.mkShell {
        packages = with pkgs; [
          python312
          python312Packages.pip
          python312Packages.virtualenv
          uv
          ruff
          pyright
          just
        ];

        shellHook = ''
          export UV_LINK_MODE=copy
          echo "Python dev shell ready (uv/ruff/pyright)."
        '';
      };
  in {
    devShells.x86_64-linux.default = mk "x86_64-linux";
    devShells.aarch64-linux.default = mk "aarch64-linux";
  };
}
