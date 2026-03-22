{
  description = "julian nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, zen-browser, ... }:
  let
    system = "x86_64-linux";
    hostname = "pc";
    username = "julian";
    homeDirectory = "/home/julian";
    codexOverlay = import ./overlays/codex.nix;
    claudeCodeOverlay = import ./overlays/claude-code.nix;
    zenBrowserOverlay = import ./overlays/zen-browser.nix { inherit zen-browser; };

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        overlays = [ codexOverlay claudeCodeOverlay zenBrowserOverlay ];
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
            "steam"
            "steam-unwrapped"
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

    cliModules = [
      ./home/common.nix
      ./home/cli.nix
      ./home/root.nix
    ];
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          networking.hostName = hostname;

          nixpkgs.overlays = [ codexOverlay claudeCodeOverlay zenBrowserOverlay ];
          nixpkgs.config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "claude-code"
              "steam"
              "steam-unwrapped"
            ];

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
        modules = cliModules;
      };
    };
  };
}
