let
  nixpkgs = import (builtins.fetchGit {
    name = "nixos-unstable-2019-10-24";
    url = https://github.com/nixos/nixpkgs/;
    rev = "4cd2cb43fb3a87f48c1e10bb65aee99d8f24cb9d";
  }) {};
  inherit (nixpkgs) lib;

in
  lib.filterAttrs (
    pname: pkg:
      let
        eval = builtins.tryEval pkg;
        meta = (builtins.tryEval (eval.value.meta or { maintainers = []; })).value or {};
      in
        if eval.success then
          builtins.any
            (m: (m.github or null) == "veprbl")
            (meta.maintainers or [])
        else
          false) nixpkgs.pkgs
