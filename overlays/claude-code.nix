final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  isLinux = prev.stdenv.hostPlatform.isLinux;
  runtimePath = prev.lib.makeBinPath (
    [ prev.ripgrep ]
    ++ prev.lib.optionals isLinux [ prev.procps prev.bubblewrap prev.socat ]
  );
  # Run ./update-claude-code.sh to update
  version = "2.1.118";
  linuxHash = "sha256:0ijf1wvhzsl7zgl2j4yvkbawbfz03zhy5v5qsk920wd420j3ndms";
  darwinAarch64Hash = "sha256:0r9nmlk0shqaca7p8l8y5mk6r42j9na40x7l8rh9rf09a7vd7ral";
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  srcInfo =
    if system == "x86_64-linux" then {
      url = "${baseUrl}/${version}/linux-x64/claude";
      hash = linuxHash;
    } else if system == "aarch64-darwin" then {
      url = "${baseUrl}/${version}/darwin-arm64/claude";
      hash = darwinAarch64Hash;
    } else
      null;
in
{
  claude-code =
    if srcInfo == null then
      prev.claude-code
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "claude-code";
        inherit version;

        src = builtins.fetchurl {
          url = srcInfo.url;
          sha256 = srcInfo.hash;
        };

        nativeBuildInputs =
          [ prev.makeBinaryWrapper ]
          ++ prev.lib.optionals isLinux [ prev.autoPatchelfHook ];

        dontUnpack = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          install -Dm755 $src $out/bin/claude
          wrapProgram $out/bin/claude \
            --set DISABLE_AUTOUPDATER 1 \
            --set USE_BUILTIN_RIPGREP 0 \
            --prefix PATH : ${runtimePath}
        '';

        meta = with prev.lib; {
          description = "Anthropic Claude Code CLI";
          homepage = "https://github.com/anthropics/claude-code";
          license = licenses.unfree;
          platforms = [ "x86_64-linux" "aarch64-darwin" ];
        };
      };
}
