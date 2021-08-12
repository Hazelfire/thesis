{ pkgs ? import <nixpkgs> {} }:
  pkgs.stdenv.mkDerivation {
    name = "HonoursThesis";
    src =./.;
    buildInputs = with pkgs; [ (texlive.combine {
                    inherit (texlive)
                    scheme-small
                    lipsum
                    subfigure
                    collection-fontsextra
                    tabu
                    varwidth
                      amsmath
                      multirow

                      ec
                      # Add other LaTeX libraries (packages) here as needed, e.g:
                      # stmaryrd amsmath pgf

                      # build tools
                      ;
                  })

                ];
    buildPhase = ''
      pdflatex --no-manual "RMIT Thesis Template.tex"
      bibtex "RMIT Thesis Template"
      pdflatex --no-manual "RMIT Thesis Template.tex"
      pdflatex --no-manual "RMIT Thesis Template.tex"
    '';
    installPhase = ''
      mkdir $out
      cp "RMIT Thesis Template.pdf" $out
    '';
}
