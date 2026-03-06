final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  # Run ./update-codex.sh to update
  version = "0.111.0";
  hash = "sha256:1183fkdzsy68rxix6hg88j2mqlg15vjhi63vjh2xlhdykhc53vgr";
in
{
  codex =
    if system != "x86_64-linux" then
      prev.codex
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "codex";
        inherit version;

        src = builtins.fetchTarball {
          url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
          sha256 = hash;
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          install -Dm755 $src/codex-x86_64-unknown-linux-musl $out/bin/codex
        '';

        meta = with prev.lib; {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          license = licenses.mit;
          platforms = [ "x86_64-linux" ];
        };
      };
}
