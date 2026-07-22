{
  description = "Arduino project";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    lib = nixpkgs.lib;
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = lib.genAttrs systems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            arduino-cli
            arduino-language-server
            clang-tools
          ];
        };
      });
  };
}
