{
  description = "Julian templates";

  outputs = { self }: {
    templates.python = {
      path = ./python;
      description = "Python project (direnv + uv/ruff/pyright)";
    };
  };
}
