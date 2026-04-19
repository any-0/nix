final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  # Run ./update-codex.sh to update
  version = "0.121.0";
  linuxHash = "sha256-J4xysD1OH2YbqCjBzPNuui+I2AdMcOPwMhHb+2MSc8Q=";
  darwinAarch64Hash = "sha256-YPcDnmOn3orkdBNqxvWT7BqRPh3coN9ZreH21utff9A=";
  srcInfo =
    if system == "x86_64-linux" then {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = linuxHash;
      binName = "codex-x86_64-unknown-linux-musl";
    } else if system == "aarch64-darwin" then {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      hash = darwinAarch64Hash;
      binName = "codex-aarch64-apple-darwin";
    } else
      null;
in
{
  codex =
    if srcInfo == null then
      prev.codex
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "codex";
        inherit version;

        src = prev.fetchurl {
          url = srcInfo.url;
          hash = srcInfo.hash;
        };

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          tar -xzf "$src"
          install -Dm755 ${srcInfo.binName} $out/bin/codex
        '';

        meta = with prev.lib; {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          license = licenses.mit;
          platforms = [ "x86_64-linux" "aarch64-darwin" ];
        };
      };
}
