final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  # Run ./update-codex.sh to update
  version = "0.118.0";
  linuxHash = "sha256:193b07087a5j2qxnb6zbj2mg0clf38vqzp2q1l2ahahhrp9bsbhn";
  darwinAarch64Hash = "sha256:1k1i1laxndjmcj6wglg6857cm2zb9dda2lkgrhd79a5sxnsyshcq";
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

        src = builtins.fetchTarball {
          url = srcInfo.url;
          sha256 = srcInfo.hash;
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          install -Dm755 $src/${srcInfo.binName} $out/bin/codex
        '';

        meta = with prev.lib; {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          license = licenses.mit;
          platforms = [ "x86_64-linux" "aarch64-darwin" ];
        };
      };
}
