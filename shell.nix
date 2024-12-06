{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "dev-shell";
  buildInputs = with pkgs; [
    # Used by build script
    tcl
    tcl-cmark # From github.com/linnnus/nix-monorepo/pkgs/tcl-cmark
    git
    coreutils-full
    # Used by Makefile to supplement build script
    fswatch
    python3
  ];
}
