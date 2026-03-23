final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  # Run ./update-codex.sh to update
  version = "0.116.0";
  hash = "sha256:1x0yxbvr6svy7i3a20cy7d4kagjzvkgqil3kg0whwi8vcaqn5zxs";
in
{
  codex =
    if system != "x86_64-linux" then
      prev.codex
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "codex";
        inherit version;

        nativeBuildInputs = [ prev.makeBinaryWrapper ];

        src = builtins.fetchTarball {
          url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
          sha256 = hash;
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          install -Dm755 $src/codex-x86_64-unknown-linux-musl $out/libexec/codex
          makeBinaryWrapper $out/libexec/codex $out/bin/codex \
            --add-flags '--search' \
            --add-flags '-c' \
            --add-flags 'model_provider="openai-http"' \
            --add-flags '-c' \
            --add-flags 'model_providers.openai-http.name="OpenAI"' \
            --add-flags '-c' \
            --add-flags 'model_providers.openai-http.wire_api="responses"' \
            --add-flags '-c' \
            --add-flags 'model_providers.openai-http.requires_openai_auth=true' \
            --add-flags '-c' \
            --add-flags 'model_providers.openai-http.supports_websockets=false'
        '';

        meta = with prev.lib; {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          license = licenses.mit;
          platforms = [ "x86_64-linux" ];
        };
      };
}
