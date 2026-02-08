{
  description = "julian nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  {
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # Enable overlay for the system pkgs (and HM if using global pkgs)
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        home-manager.nixosModules.home-manager
        { home-manager.users.julian = import ./home.nix; }
      ];
    };
  };
}
