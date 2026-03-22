{ barSource }:
final: prev:
let
  runtimeInputs = with prev; [
    bluez
    iproute2
    niri
    upower
    wireplumber
  ];
in
{
  julian-bar = prev.rustPlatform.buildRustPackage {
    pname = "julian-bar";
    version = "0.1.0";

    src = barSource;

    cargoLock = {
      lockFile = barSource + "/Cargo.lock";
    };

    nativeBuildInputs = with prev; [
      makeWrapper
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

    postFixup = ''
      wrapProgram $out/bin/bar \
        --prefix PATH : ${prev.lib.makeBinPath runtimeInputs}
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
