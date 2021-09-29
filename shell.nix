{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name="thesis";
  buildInputs = with pkgs; [ 
    pandoc 
    haskellPackages.pandoc-crossref
    (texlive.combine { inherit (texlive) scheme-small latexmk; }) 
    yarn 
    nodejs
    inotify-tools
  ];
}
