{ barSource }:
final: prev:
{
  julian-bar = prev.rustPlatform.buildRustPackage {
    pname = "julian-bar";
    version = "0.1.0";

    src = barSource;

    cargoLock = {
      lockFile = barSource + "/Cargo.lock";
    };

    nativeBuildInputs = with prev; [
      pkg-config
      wrapGAppsHook3
    ];

    buildInputs = with prev; [
      cairo
      gdk-pixbuf
      glib
      gtk-layer-shell
      gtk3
    ];

    BAR_ASSETS_DIR = "${placeholder "out"}/share/bar/assets";

    postInstall = ''
      mkdir -p $out/share/bar
      cp -r assets $out/share/bar/assets
    '';

    meta = with prev.lib; {
      description = "Custom Niri bar";
      homepage = "https://gl.any-0.com/bar";
      license = licenses.mit;
      mainProgram = "bar";
      platforms = platforms.linux;
    };
  };
}
