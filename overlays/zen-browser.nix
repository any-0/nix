{ zen-browser }:
final: prev:
{
  zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
}
