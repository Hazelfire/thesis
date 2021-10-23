{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "govhack";
  buildInputs = with pkgs; [ nodePackages.yarn miller nodejs python3 ];
}
