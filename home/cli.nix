{ config, lib, pkgs, ... }:

let
  zsh = "${pkgs.zsh}/bin/zsh";
  startZsh = ''
    # Session launchers can run noninteractive Bash on a terminal.
    # Preserve their command instead of replacing it with a login shell.
    case $- in
      *i*) ;;
      *) return ;;
    esac
    if [ -z "''${ZSH_VERSION:-}" ] && [ -t 0 ] && [ -t 1 ]; then
      export SHELL="${zsh}"
      exec "${zsh}" -l
    fi
  '';
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  iosevkaTermSlab = pkgs.callPackage ../dotfiles/fonts/iosevka-termslab-custom { };
in
{
  # A standalone CLI activation replaces the desktop's Home Manager generation.
  home.activation.checkCliHost = lib.hm.dag.entryBefore [ "checkLinkTargets" "writeBoundary" ] ''
    if [[ -e /etc/NIXOS || -e /run/current-system/nixos-version || -e /.host-etc/NIXOS ]]; then
      echo "The CLI profile cannot be activated on NixOS: it would remove desktop configuration." >&2
      echo "Use ~/nix/scripts/cli/switch to apply the system and desktop configuration." >&2
      exit 1
    fi
  '';

  home.file.".profile".text = startZsh;
  home.file.".bashrc".text = startZsh;

  # WSL can't install fonts into the Windows host's font directory, so drop the
  # patched ttf where it can be installed there by hand instead. Every other CLI
  # host has no Windows to hand it to, and may not even have the repo checked out
  # at this path, so gate on both rather than failing activation over a font.
  home.activation.exportIosevkaTermSlabTtf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kernel=""
    if [[ -r /proc/sys/kernel/osrelease ]]; then
      read -r kernel < /proc/sys/kernel/osrelease
    fi

    font_export_dir="${dotfilesDir}/fonts/iosevka-termslab-custom"
    if [[ "$kernel" == *icrosoft* || -n "''${WSL_DISTRO_NAME:-}" ]] \
      && [[ -d "$font_export_dir" ]]; then
      ${lib.getExe' pkgs.coreutils "cp"} -f \
        "${iosevkaTermSlab}/share/fonts/truetype/IosevkaTermSlabNerdFontMono-Custom-Regular.ttf" \
        "$font_export_dir/IosevkaTermSlabNerdFontMono-Custom-Regular.ttf"
    fi
  '';
}
