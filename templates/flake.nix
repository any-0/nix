{
  description = "Julian templates";

  outputs = { self }: {
    templates.blank = {
      path = ./blank;
      description = "Blank project";
    };
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
    templates.rust = {
      path = ./rust;
      description = "Rust project";
    };
    templates.tex = {
      path = ./latex;
      description = "LaTeX project";
    };
    templates.arduino = {
      path = ./arduino;
      description = "Arduino project";
    };
  };
}
