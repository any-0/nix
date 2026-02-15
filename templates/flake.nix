{
  description = "Julian templates";

  outputs = { self }: {
    templates.c = {
      path = ./c;
      description = "C project (gcc + make + gdb + clang-format)";
    };
    templates.python = {
      path = ./python;
      description = "Python project (direnv + uv/ruff/pyright)";
    };
  };
}
