final: prev:
let
  version = "0.98.0";
  tag = "rust-v${version}";
  system = prev.stdenv.hostPlatform.system;
in
{
  codex =
    if system != "x86_64-linux" then
      prev.codex
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "codex";
        version = version;

        src = prev.fetchurl {
          url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-musl.tar.gz";
          hash = "sha256-wJ7m7G8e71iCS96hTvsQre5U4OPFzL+k4/862bDd3IM=";
        };

        dontConfigure = true;
        dontBuild = true;
        dontUnpack = true;

        installPhase = ''
          tar -xzf $src
          install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
        '';

        meta = with prev.lib; {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          license = licenses.mit;
          platforms = [ "x86_64-linux" ];
        };
      };
}
