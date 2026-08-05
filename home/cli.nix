{ config, lib, pkgs, ... }:

let
  zsh = "${pkgs.zsh}/bin/zsh";
  startZsh = ''
    if [ -z "''${ZSH_VERSION:-}" ] && [ -t 0 ] && [ -t 1 ]; then
      export SHELL="${zsh}"
      exec "${zsh}" -l
    fi
  '';
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  iosevkaTermSlab = pkgs.callPackage ../dotfiles/fonts/iosevka-termslab-custom { };
in
{
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
