let
  nixpkgs = import (builtins.fetchGit {
    name = "nixos-unstable-2019-10-24";
    url = https://github.com/nixos/nixpkgs/;
    rev = "4cd2cb43fb3a87f48c1e10bb65aee99d8f24cb9d";
  }) {};
in
  {
    inherit (nixpkgs) hello;
  }
