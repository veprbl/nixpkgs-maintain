let
  nixpkgs = import (builtins.fetchGit {
    name = "nixos-19.09-2019-10-24";
    url = https://github.com/nixos/nixpkgs/;
    rev = "f6dac8083874408fe287525007d3da9decd9bf44";
    ref = "release-19.09";
  }) {};
  inherit (nixpkgs) lib;

  blacklist = [ "bluejeans-gui" ];
in
  lib.filterAttrs
    (pname: pkg:
      let
        eval = builtins.tryEval pkg;
        meta = (builtins.tryEval (eval.value.meta or { maintainers = []; })).value or {};
      in
        if eval.success && !(builtins.elem pname blacklist) then
          builtins.any
            (m: (m.github or null) == "veprbl")
            (meta.maintainers or [])
        else
          false)
    nixpkgs.pkgs
