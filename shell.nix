{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name="thesis";
  buildInputs = with pkgs; [ 
    pandoc 
    haskellPackages.pandoc-crossref
    haskellPackages.pandoc-csv2table
    (texlive.combine { inherit (texlive) scheme-small latexmk biblatex; }) 
    yarn 
    nodejs
    inotify-tools
  ];
}
