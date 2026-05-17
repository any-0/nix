{ homeDirectory, pkgs, ... }:

let
  smbCredentials = "${homeDirectory}/nix/secrets/smb-nas.cred";
  smbMountOptions = [
    "credentials=${smbCredentials}"
    "uid=1000"
    "gid=100"
    "iocharset=utf8"
    "x-systemd.automount"
    "nofail"
    "x-systemd.idle-timeout=60"
  ];
in
{
  boot.supportedFilesystems = [ "cifs" ];

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  fileSystems = {
    "/mnt/home1" = {
      device = "//192.168.0.227/home";
      fsType = "cifs";
      options = smbMountOptions;
    };

    "/mnt/home2" = {
      device = "//192.168.0.227/home2";
      fsType = "cifs";
      options = smbMountOptions;
    };
  };
}
