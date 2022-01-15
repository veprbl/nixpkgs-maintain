let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) lib recurseIntoAttrs;

  /* Filters attributes which can evaluate

     Type:
       filter_eval :: AttrSet -> AttrSet
  */
  filter_eval = attrs:
    builtins.mapAttrs (_: value: value.value)
      (lib.filterAttrs (_: value: value.success)
        (builtins.mapAttrs (_: value: builtins.tryEval value) attrs));

  /* Checks whether attrset is not empty

    Type:
      isNotEmptyAttrs :: AttrSet -> bool
  */
  isNotEmptyAttrs = attrs: builtins.length (builtins.attrNames attrs) != 0;

  /* Implements a blacklist of attribute names that we should not try to
     recurse into

    Type:
      isBlacklistedRecursion :: string -> bool
  */
  isBlacklistedRecursion = name: builtins.elem name [
    "__splicedPackages"
    "pkgs"
    "buildPackages"
    "hostPackages"
    "targetPackages"
    "pkgsBuildBuild"
    "pkgsBuildHost"
    "pkgsBuildTarget"
    "pkgsHostHost"
    "pkgsHostTarget"
    "pkgsTargetTarget"
  ];

  /* Recursively traverse set of packages, return packages that pass _filter

     Type:
       recurse_filter :: (AttrSet -> AttrSet) -> AttrSet -> AttrSet
  */
  recurse_filter = _recurse_filter [];
  _recurse_filter = visited: _filter: attrs:
    let
      _attrs = filter_eval attrs;
      pkgs = _filter _attrs;
      nested_attrsets = lib.filterAttrs (name: value:
        builtins.isAttrs value
        && value ? "recurseForDerivations"
        && !(isBlacklistedRecursion name)
        && !(builtins.elem name visited)
        ) _attrs;
      recursed_attrs =
        builtins.mapAttrs (name: recurseIntoAttrs) (
          lib.filterAttrs (name: isNotEmptyAttrs) (
            builtins.mapAttrs (name:
              builtins.trace "${builtins.concatStringsSep "." visited} recursing into ${name}"
              (_recurse_filter (visited ++ [ name ]) _filter))
            nested_attrsets));
    in
      pkgs // recursed_attrs;

  /* Select packages that evaluate and are maintained by me

     Type:
       filter_packages_by_blacklist :: [string] -> AttrSet -> AttrSet
  */
  filter_packages_by_blacklist = blacklist:
    lib.filterAttrs (pname: pkg: !(builtins.elem pname blacklist));

  /* Select packages that evaluate and are maintained by me

     Type:
       filter_packages_by_maintainer :: string -> AttrSet -> AttrSet
  */
  filter_packages_by_maintainer = maintainer:
    lib.filterAttrs (pname: pkg:
      let
        maintainers_eval = builtins.tryEval ((pkg.meta or {}).maintainers or []);
      in
        if maintainers_eval.success then
          builtins.any
            (m: (builtins.tryEval (m.github or null)).value == maintainer)
            maintainers_eval.value
        else
          false);

  build_filter = pkgs:
    filter_packages_by_blacklist [ "bluejeans-gui" ]
      (filter_packages_by_maintainer "veprbl" pkgs);
in
builtins.mapAttrs (name: value: recurseIntoAttrs (recurse_filter build_filter value))
  {
    inherit (nixpkgs) pkgs pkgsi686Linux;
  }
