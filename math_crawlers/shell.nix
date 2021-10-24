{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "govhack";
  buildInputs = with pkgs; [ nodejs nodePackages.yarn miller python3 python3Packages.pip ];
}
