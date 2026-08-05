{ fetchurl, fontforge, lib, stdenvNoCC, unzip }:

let
  connectorCell =
    if stdenvNoCC.hostPlatform.isDarwin then
      { top = 1090; bottom = -410; railTop = 1600; railBottom = -700; armsInside = false; }
    else
      { top = 1000; bottom = -277; railTop = 1000; railBottom = -345; armsInside = true; };

  # Logos come from their vendor's own vector rather than a trace, which keeps
  # the artwork faithful and gives each source a recorded origin. Fetching them
  # is what keeps that origin in one place; nothing here needs a copy in-tree.

  # Anthropic publishes no brand-asset page, so this comes from Simple Icons,
  # whose entry cites https://claude.ai as its source. Pinned to a release tag:
  # `develop` is rewritten in place, and they drop brands at major versions.
  claudeLogo = fetchurl {
    url = "https://raw.githubusercontent.com/simple-icons/simple-icons/16.28.0/icons/claude.svg";
    hash = "sha256-LW/aeesY3czKNbeZ7rPOzg36vCJSDOOxCr0lZo35+pM=";
  };

  # OpenAI's own brand CDN. The name carries a year but no version, so the file
  # can be replaced under this URL; if the hash ever stops matching, re-check
  # https://openai.com/brand for the current archive rather than assuming the
  # download corrupted.
  openaiLogos = fetchurl {
    url = "https://cdn.openai.com/brand/OpenAI-Logos-2025.zip";
    hash = "sha256-ssTNHoa752vcSUanLQFO+kVSQMF39IeP1ozJuIxx0uw=";
  };

  # OpenCode's mark is pinned to the same Simple Icons release as Claude's.
  opencodeLogo = fetchurl {
    url = "https://raw.githubusercontent.com/simple-icons/simple-icons/16.28.0/icons/opencode.svg";
    hash = "sha256-b30gMgC6BRzbqnJsTeCnKc7j8c7EeVPxiTmdlRr1jEw=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "iosevka-term-slab-nerd-font-custom";
  version = "3.5.0";

  src = fetchurl {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/IosevkaTermSlab.zip";
    hash = "sha256-lkPI5lVQ5WweW6YuV9av79QqNI6YdqloVLIJVEiKjnc=";
  };

  nativeBuildInputs = [ fontforge unzip ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    font_dir="$out/share/fonts/truetype"
    mkdir -p "$font_dir"
    unzip -j "$src" 'IosevkaTermSlabNerdFontMono-*.ttf' -d "$font_dir"

    logo_dir="$NIX_BUILD_TOP/logos"
    mkdir -p "$logo_dir"
    unzip -j "${openaiLogos}" \
      'OpenAI-logos(new)/SVGs/OpenAI-black-monoblossom.svg' -d "$logo_dir"

    fontforge -script ${./create-private-use-glyphs.py} \
      "$font_dir/IosevkaTermSlabNerdFontMono-Regular.ttf" \
      "$font_dir/IosevkaTermSlabNerdFontMono-Custom-Regular.ttf" \
      "${claudeLogo}" \
      "$logo_dir/OpenAI-black-monoblossom.svg" \
      "${opencodeLogo}" \
      ${toString connectorCell.top} \
      ${toString connectorCell.bottom} \
      ${toString connectorCell.railTop} \
      ${toString connectorCell.railBottom} \
      ${lib.boolToString connectorCell.armsInside}

    # The patched regular keeps the family name of the one it was built from, so
    # shipping both leaves fontconfig two candidates for the same family/style
    # and it is free to pick the unpatched one.
    rm "$font_dir/IosevkaTermSlabNerdFontMono-Regular.ttf"

    runHook postInstall
  '';

  meta = {
    description = "Iosevka Term Slab Nerd Font with custom private-use glyphs";
    homepage = "https://github.com/ryanoasis/nerd-fonts";
    # Covers the typeface only. The private-use logo glyphs are their owners'
    # marks, drawn unaltered from the vendors' artwork, and the OFL says nothing
    # about them either way.
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
