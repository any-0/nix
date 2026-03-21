final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  # Run ./update-claude-code.sh to update
  version = "2.1.81";
  hash = "sha256:10f2iz0s5gbzbmg9izl03kgyic1mqfd7464mvl48n8ynj5akyzh4";
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
in
{
  claude-code =
    if system != "x86_64-linux" then
      prev.claude-code
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "claude-code";
        inherit version;

        src = builtins.fetchurl {
          url = "${baseUrl}/${version}/linux-x64/claude";
          sha256 = hash;
        };

        nativeBuildInputs = [ prev.autoPatchelfHook prev.makeBinaryWrapper ];

        dontUnpack = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          install -Dm755 $src $out/bin/claude
          wrapProgram $out/bin/claude \
            --set DISABLE_AUTOUPDATER 1 \
            --set USE_BUILTIN_RIPGREP 0 \
            --prefix PATH : ${prev.lib.makeBinPath [
              prev.procps
              prev.ripgrep
              prev.bubblewrap
              prev.socat
            ]}
        '';

        meta = with prev.lib; {
          description = "Anthropic Claude Code CLI";
          homepage = "https://github.com/anthropics/claude-code";
          license = licenses.unfree;
          platforms = [ "x86_64-linux" ];
        };
      };
}
