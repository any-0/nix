{ fetchurl, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "macmon";
  version = "0.8.2";
  src = fetchurl {
    url = "https://github.com/vladkens/macmon/releases/download/v0.8.2/macmon-v0.8.2.tar.gz";
    sha256 = "588d5bde79885ba36f693e5150911c10c3ad208a2e418a3f2aa827ac84a2d973";
  };
  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    install -Dm755 macmon "$out/bin/macmon"
    runHook postInstall
  '';
}
