{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "dev-shell";
  buildInputs = with pkgs; [
    # Used by build script
    tcl
    smu
    git
    coreutils-full
    # Used by Makefile to supplement build script
    fswatch
    python3
  ];
}
