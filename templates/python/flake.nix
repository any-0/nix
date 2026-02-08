{
  description = "Python project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    python-dev.url = "path:/home/julian/nix/devshells/python";
  };

  outputs = { self, nixpkgs, python-dev }:
  let
    system = "x86_64-linux";
  in {
    devShells.${system}.default = python-dev.devShells.${system}.default;
  };
}
