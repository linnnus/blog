{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "dev-shell";
  buildInputs = with pkgs; [
    # Used by build script
    tcl-8_5
    tcllib
    git
    coreutils-full
    # Used by Makefile to supplement build script
    fswatch
    python3
  ];
}
