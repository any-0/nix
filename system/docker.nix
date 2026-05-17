{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  virtualisation.containerd.enable = true;

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];
}
