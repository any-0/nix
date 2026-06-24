{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    coreutils
    wakeonlan
  ];

  home.sessionPath = [
    "${pkgs.coreutils}/bin"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  xdg.configFile."zsh/.zprofile".text = ''
    unset __HM_SESS_VARS_SOURCED
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    typeset -U path
  '';

  home.file.".local/bin/mount-nas-smb" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      user="''${SMB_USER:-${config.home.username}}"
      hosts="''${SMB_HOSTS:-192.168.0.227}"
      base="$HOME/mnt"
      server=""

      for host in $hosts; do
        if /usr/bin/nc -G 2 -z "$host" 445 >/dev/null 2>&1; then
          server="$host"
          break
        fi
      done

      if [[ -z "$server" ]]; then
        echo "No SMB host reachable on port 445. Tried: $hosts" >&2
        exit 1
      fi

      mkdir -p "$base/home1" "$base/home2"

      mount_share() {
        local share="$1"
        local mountpoint="$2"

        if mount | grep -q " on $mountpoint "; then
          echo "$mountpoint already mounted"
          return
        fi

        echo "mounting //$user@$server/$share -> $mountpoint"
        /sbin/mount_smbfs "//$user@$server/$share" "$mountpoint"
      }

      mount_share home "$base/home1"
      mount_share home2 "$base/home2"
    '';
  };

  home.file.".local/bin/umount-nas-smb" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      timeout=${pkgs.coreutils}/bin/timeout

      unmount_one() {
        local mountpoint="$1"

        if ! mount | grep -q " on $mountpoint "; then
          echo "$mountpoint not mounted"
          return
        fi

        echo "force unmounting $mountpoint"

        if "$timeout" 5s /usr/sbin/diskutil unmount force "$mountpoint" >/dev/null 2>&1; then
          return
        fi

        if "$timeout" 5s /sbin/umount -f "$mountpoint" >/dev/null 2>&1; then
          return
        fi

        echo "failed or timed out unmounting $mountpoint" >&2
      }

      unmount_one "$HOME/mnt/home1"
      unmount_one "$HOME/mnt/home2"
    '';
  };

  services.gpg-agent = {
    pinentry.package = pkgs.pinentry_mac;
  };
}
