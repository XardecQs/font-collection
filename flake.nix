{
  description = "Colección de fuentes personalizadas para NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      fontDirs = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./src)
      );

      mkFontPkg =
        pkgs: name:
        pkgs.stdenvNoCC.mkDerivation {
          pname = name;
          version = "1.0";
          src = ./src + "/${name}";
          installPhase = ''
            mkdir -p $out/share/fonts/opentype
            mkdir -p $out/share/fonts/truetype
            find . -iname '*.otf' -exec cp {} $out/share/fonts/opentype/ \; || true
            find . -type f \( -iname '*.ttf' -o -iname '*.ttc' \) \
              -exec cp {} $out/share/fonts/truetype/ \; || true
          '';
          meta = with pkgs.lib; {
            license = licenses.unfree;
            platforms = platforms.all;
          };
        };

      mkSystemPackages =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fontPkgs = builtins.listToAttrs (
            map (name: {
              inherit name;
              value = mkFontPkg pkgs name;
            }) fontDirs
          );
        in
        fontPkgs
        // {
          default = pkgs.symlinkJoin {
            name = "font-collection";
            paths = builtins.attrValues fontPkgs;
            meta = with pkgs.lib; {
              description = "Colección completa de fuentes";
              license = licenses.unfree;
              platforms = platforms.all;
            };
          };
        };
    in
    {
      packages = forEachSystem mkSystemPackages;

      nixosModules.default =
        { pkgs, ... }:
        let
          fontPkgs = builtins.listToAttrs (
            map (name: {
              inherit name;
              value = mkFontPkg pkgs name;
            }) fontDirs
          );
        in
        {
          fonts.packages = builtins.attrValues fontPkgs;
        };
    };
}
