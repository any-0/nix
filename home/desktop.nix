{ config, pkgs, lib, dotFile, ... }:

let
  t3CodeDir = "${config.xdg.dataHome}/t3-code";
  t3CodeAppImage = "${t3CodeDir}/T3-Code.AppImage";
  t3Code = pkgs.writeShellScriptBin "t3-code" ''
    # The updater relaunches the AppImage inside the same FHS environment.
    export APPIMAGE_EXTRACT_AND_RUN=1
    # This Electron build hangs during native Wayland startup on niri.
    export XDG_SESSION_TYPE=x11
    exec ${lib.getExe pkgs.appimage-run} "${t3CodeAppImage}" "$@"
  '';
  t3CodeDesktop = pkgs.makeDesktopItem {
    name = "com.t3tools.T3Code";
    desktopName = "T3 Code";
    comment = "Interface for coding agents";
    exec = "${lib.getExe t3Code} %U";
    icon = "applications-development";
    terminal = false;
    categories = [ "Development" ];
    mimeTypes = [ "x-scheme-handler/t3code" ];
  };
  keyringPython = pkgs.python3.withPackages (python: [ python.dbus-python ]);
  keyringPasswordless = pkgs.writeScriptBin "keyring-passwordless" ''
    #!${keyringPython}/bin/python3
    import getpass
    import os
    from pathlib import Path
    import shutil
    import sys
    import tempfile

    import dbus

    if not sys.stdin.isatty():
        raise SystemExit("Run keyring-passwordless in a terminal so password input stays hidden.")

    bus = dbus.SessionBus()
    service_object = bus.get_object("org.freedesktop.secrets", "/org/freedesktop/secrets")
    service = dbus.Interface(service_object, "org.freedesktop.Secret.Service")
    collection = service.ReadAlias("login")
    if collection == "/":
        raise SystemExit("No login keyring exists.")

    print("Remove the login keyring password while preserving its credentials.")
    print("The keyring will no longer encrypt those credentials on disk.")
    password = getpass.getpass("Current keyring password (usually your login password): ")

    keyring_dir = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "keyrings"
    backup_fd, backup_path = tempfile.mkstemp(prefix="login.keyring.backup-", dir=keyring_dir)
    os.close(backup_fd)
    shutil.copyfile(keyring_dir / "login.keyring", backup_path)
    _, session = service.OpenSession("plain", dbus.String("", variant_level=1))
    original = (session, dbus.ByteArray(b""), dbus.ByteArray(password.encode()), "text/plain")
    empty = (session, dbus.ByteArray(b""), dbus.ByteArray(b""), "text/plain")
    internal = dbus.Interface(service_object, "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface")
    try:
        internal.ChangeWithMasterPassword(collection, original, empty)
    except dbus.DBusException as error:
        raise SystemExit(error.get_dbus_message())
    finally:
        dbus.Interface(bus.get_object("org.freedesktop.secrets", session), "org.freedesktop.Secret.Session").Close()

    print("Done. The login keyring now has no password; stored credentials were preserved.")
    print(f"Original keyring backup: {backup_path}")
  '';
in

{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  xdg.configFile."quickshell/bar" = dotFile "quickshell/bar";
  xdg.dataFile."dbus-1/services/org.freedesktop.Notifications.service" =
    dotFile "quickshell/org.freedesktop.Notifications.service";
  xdg.configFile."niri" = dotFile "niri";
  xdg.configFile."zen/odpbn0jp.Default Profile/user.js".text = ''
    user_pref("zen.window-sync.enabled", false);
  '';

  services.polkit-gnome.enable = true;

  home.file.".local/bin/t3-code".source = "${t3Code}/bin/t3-code";
  home.file.".local/bin/keyring-passwordless".source = "${keyringPasswordless}/bin/keyring-passwordless";
  # Keep the local entry managed too: upstream's launcher skips appimage-run.
  xdg.dataFile."applications/com.t3tools.T3Code.desktop".source =
    "${t3CodeDesktop}/share/applications/com.t3tools.T3Code.desktop";

  # Keep the AppImage writable so Electron's updater can replace it.
  home.activation.installT3Code = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -f "${t3CodeAppImage}" ]]; then
      t3_url="$(${lib.getExe pkgs.curl} -fsSL \
        https://api.github.com/repos/pingdotgg/t3code/releases/latest \
        | ${lib.getExe pkgs.jq} -er '.assets[] | select(.name | endswith("-x86_64.AppImage")) | .browser_download_url')"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${t3CodeDir}"
      $DRY_RUN_CMD ${lib.getExe pkgs.curl} -fL "$t3_url" -o "${t3CodeAppImage}.download"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod +x "${t3CodeAppImage}.download"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "${t3CodeAppImage}.download" "${t3CodeAppImage}"
    fi
  '';

  home.packages = with pkgs; [
    t3CodeDesktop
    evince
    swaybg
    libnotify
    grim
    slurp
    obs-studio
    vlc
    wl-clipboard
    kitty
    playerctl
    swaylock
    xwayland-satellite
    zen-browser
  ] ++ [
    pkgs.kdePackages.dolphin
  ];
}
