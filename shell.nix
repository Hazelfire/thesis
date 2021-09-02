{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name="thesis";
  buildInputs = with pkgs; [ pandoc  (texlive.combine { inherit (texlive) scheme-small latexmk; }) yarn nodejs];
}
