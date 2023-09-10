{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "dev-shell";
  buildInputs = with pkgs; [ tcl smu git coreutils-full ];
}
