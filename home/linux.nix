{ pkgs, ... }:

{
  home.sessionVariables = {
    DOCKER_CLI_PLUGIN_EXTRA_DIRS = "${pkgs.docker-compose}/libexec/docker/cli-plugins";
  };

  services.gpg-agent = {
    pinentry.package = pkgs.pinentry-tty;
  };

  home.packages = with pkgs; [
    procps
    xclip
  ];
}
