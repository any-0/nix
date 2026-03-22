{ zen-browser }:
final: prev:
{
  zen-browser = zen-browser.packages.${prev.system}.default;
}
