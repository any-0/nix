{
  # Keep this to colors that define a scheme. Application roles are mapped in
  # the templates; format-specific values are derived by default.nix.
  dark = {
    variant = "dark";

    background = "202026";
    foreground = "f2f2f4";
    surface = "292932";
    surfaceRaised = "454550";
    muted = "8b8b95";

    accent = "7aa2f7";
    secondary = "5bc8af";
    success = "8bd49c";
    warning = "e0af68";
    danger = "ff7a90";
    selection = "34495e";
    diffAdd = "244333";
    diffDelete = "4a2932";
    diffChange = "4a4029";
  };

  light = {
    variant = "light";

    background = "fcf9f0";
    foreground = "000000";
    surface = "e8e8e8";
    surfaceRaised = "cccccc";
    muted = "888888";

    accent = "0074b1";
    secondary = "009393";
    success = "008800";
    warning = "664400";
    danger = "8b0000";
    selection = "c4ffff";
    diffAdd = "9be7a7";
    diffDelete = "f2a6a6";
    diffChange = "f2dea0";
  };
}
