{ config, lib, pkgs, ... }:

let
  iosevkaTermSlab = pkgs.callPackage ../dotfiles/fonts/iosevka-termslab-custom { };
  fontDir = "${iosevkaTermSlab}/share/fonts/truetype";
in
{
  home.file."Applications/PC.app" = {
    source = ../dotfiles/pc-moonlight/PC.app;
    recursive = true;
  };

  home.packages = with pkgs; [
    coreutils
    (pkgs.callPackage ./macmon.nix { })
    wakeonlan
    yabai
  ];

  home.sessionPath = [
    "${pkgs.coreutils}/bin"
  ];

  home.activation.installIosevkaTermSlab = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    font_dir="${config.home.homeDirectory}/Library/Fonts"
    ${lib.getExe' pkgs.coreutils "mkdir"} -p "$font_dir"

    for font in \
      IosevkaTermSlabNerdFontMono-Custom-Regular.ttf \
      IosevkaTermSlabNerdFontMono-Bold.ttf \
      IosevkaTermSlabNerdFontMono-Italic.ttf \
      IosevkaTermSlabNerdFontMono-BoldItalic.ttf
    do
      ${lib.getExe' pkgs.coreutils "rm"} -f "$font_dir/$font"
      ${lib.getExe' pkgs.coreutils "cp"} "${fontDir}/$font" "$font_dir/$font"
    done

    /usr/bin/atsutil databases -removeUser || true
    /usr/bin/killall fontd || true
    /usr/bin/atsutil fonts -list >/dev/null
  '';

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
      hosts="''${SMB_HOSTS:-192.168.0.112}"
      base="$HOME/storage"
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

      mkdir -p "$base/media1" "$base/media2" "$base/backups"

      mount_share() {
        local share="$1"
        local mountpoint="$2"

        if mount | grep -q " on $mountpoint "; then
          echo "$mountpoint already mounted"
          return
        fi

        echo "mounting //$user@$server/$share -> $mountpoint"
        /sbin/mount_smbfs "//$user''${password:+:$password}@$server/$share" "$mountpoint"
      }

      # mount_smbfs does not consult the keychain itself. Store the password once with:
      #   security add-internet-password -a "$user" -s <server> -r 'smb ' -w '<password>' -T /usr/bin/security
      password="$(/usr/bin/security find-internet-password -a "$user" -s "$server" -w 2>/dev/null || true)"

      mount_share media1 "$base/media1"
      mount_share media2 "$base/media2"
      mount_share backups "$base/backups"
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

      unmount_one "$HOME/storage/media1"
      unmount_one "$HOME/storage/media2"
      unmount_one "$HOME/storage/backups"
    '';
  };

  services.gpg-agent = {
    pinentry.package = pkgs.pinentry_mac;
  };

  xdg.configFile."yabai/yabairc" = {
    executable = true;
    text = ''
      #!/usr/bin/env sh
      ${lib.getExe pkgs.yabai} -m config focus_follows_mouse autofocus
    '';
  };

  # Mount the NAS shares at login and every 5 minutes (no-op when already mounted).
  # Password comes from the login keychain entry for julian@192.168.0.112.
  launchd.agents.mount-nas-smb = {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.homeDirectory}/.local/bin/mount-nas-smb" ];
      RunAtLoad = true;
      StartInterval = 300;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mount-nas-smb.err.log";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mount-nas-smb.out.log";
    };
  };

  launchd.agents.yabai = {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe pkgs.yabai) ];
      ProcessType = "Interactive";
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/yabai.err.log";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/yabai.out.log";
    };
  };
}
