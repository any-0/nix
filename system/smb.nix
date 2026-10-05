{ homeDirectory, ... }:

let
  smbCredentials = "${homeDirectory}/.config/samba/nas.cred";
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

  fileSystems = {
    "${homeDirectory}/storage/media1" = {
      device = "//192.168.0.112/media1";
      fsType = "cifs";
      options = smbMountOptions;
    };

    "${homeDirectory}/storage/media2" = {
      device = "//192.168.0.112/media2";
      fsType = "cifs";
      options = smbMountOptions;
    };

    "${homeDirectory}/storage/backups" = {
      device = "//192.168.0.112/backups";
      fsType = "cifs";
      options = smbMountOptions;
    };
  };
}
