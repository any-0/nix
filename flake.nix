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
    homeDirectory = "/home/${username}";

    zenBrowserOverlay = final: prev: {
      zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
    };
    unfreePackageNames = [
      "discord"
      "steam"
      "steam-unwrapped"
    ];
    allowUnfreePredicate = pkg:
      builtins.elem (nixpkgs.lib.getName pkg) unfreePackageNames;
    overlaysFor = system:
      let
        isLinux = builtins.match ".*-linux" system != null;
      in
        nixpkgs.lib.optionals isLinux [ zenBrowserOverlay ];

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        overlays = overlaysFor system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };

    mkHome = { modules, system, username, homeDirectory }:
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
      ./home/linux.nix
      ./home/desktop.nix
    ];

    cliModules = [
      ./home/common.nix
      ./home/linux.nix
    ];

    darwinModules = [
      ./home/common.nix
      ./home/darwin.nix
    ];
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit username homeDirectory;
      };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          networking.hostName = hostname;

          nixpkgs.overlays = overlaysFor system;
          nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = { imports = desktopModules; };
        }
      ];
    };

    homeConfigurations = {
      desktop = mkHome {
        inherit system username homeDirectory;
        modules = desktopModules;
      };

      cli = mkHome {
        inherit system username homeDirectory;
        modules = cliModules;
      };

      mac = mkHome {
        system = "aarch64-darwin";
        inherit username;
        homeDirectory = "/Users/${username}";
        modules = darwinModules;
      };
    };
  };
}
