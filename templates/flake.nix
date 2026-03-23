{
  description = "Julian templates";

  outputs = { self }: {
    templates.c = {
      path = ./c;
      description = "C project";
    };
    templates.latex = {
      path = ./latex;
      description = "LaTeX project";
    };
    templates.python = {
      path = ./python;
      description = "Python project";
    };
    templates.pyts = {
      path = ./pyts;
      description = "TypeScript + Python project";
    };
    templates.tex = {
      path = ./latex;
      description = "LaTeX project";
    };
  };
}
