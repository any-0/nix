{
  description = "Julian templates";

  outputs = { self }: {
    templates.c = {
      path = ./c;
      description = "C project";
    };
    templates.python = {
      path = ./python;
      description = "Python project";
    };
    templates.pyts = {
      path = ./pyts;
      description = "TypeScript + Python project";
    };
  };
}
