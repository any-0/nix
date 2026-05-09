{ pkgs, ... }:

{
  home.packages = with pkgs; [
    coreutils
    wakeonlan
  ];

  home.sessionPath = [
    "${pkgs.coreutils}/bin"
  ];

  xdg.configFile."zsh/.zprofile".text = ''
    unset __HM_SESS_VARS_SOURCED
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    typeset -U path
  '';

  services.gpg-agent = {
    pinentry.package = pkgs.pinentry_mac;
  };
}
