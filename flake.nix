{
  description = "julian nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    username = "julian";
    homeDirectory = "/home/julian";
    codexOverlay = import ./overlays/codex.nix;
    claudeCodeOverlay = import ./overlays/claude-code.nix;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        overlays = [ codexOverlay claudeCodeOverlay ];
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
          ];
      };

    mkHome = {
      modules,
      system ? "x86_64-linux",
      username ? "julian",
      homeDirectory ? "/home/julian",
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        modules = modules ++ [
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];
      };

    desktopModules = [
      ./home/common.nix
      ./home/desktop.nix
    ];

    wslModules = [
      ./home/common.nix
      ./home/wsl.nix
      ./home/root.nix
    ];
  in
  {
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ codexOverlay ];

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };

    homeConfigurations = {
      "julian-desktop" = mkHome {
        inherit system username homeDirectory;
        modules = desktopModules;
      };

      "julian-cli" = mkHome {
        inherit system username homeDirectory;
        modules = wslModules;
      };
    };
  };
}
