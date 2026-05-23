{
  description = "Custom font collection for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      mkFontPkgs = pkgs: src: rec {
        centuryGothicPro = pkgs.stdenvNoCC.mkDerivation {
          pname = "century-gothic-pro";
          version = "1.0";
          inherit src;
          installPhase = ''
            mkdir -p $out/share/fonts/opentype
            cp "$src/Century Gothic Pro"/*.otf $out/share/fonts/opentype/
          '';
          meta = with pkgs.lib; {
            description = "Century Gothic Pro font family";
            license = licenses.unfree;
            platforms = platforms.all;
          };
        };

        sanFranciscoFamily = pkgs.stdenvNoCC.mkDerivation {
          pname = "san-francisco-family";
          version = "1.0";
          inherit src;
          installPhase = ''
            mkdir -p $out/share/fonts/opentype
            find "$src/San Francisco family" -name '*.otf' -exec cp {} $out/share/fonts/opentype/ \;
          '';
          meta = with pkgs.lib; {
            description = "San Francisco font family by Apple";
            license = licenses.unfree;
            platforms = platforms.all;
          };
        };

        windowsFonts = pkgs.stdenvNoCC.mkDerivation {
          pname = "windows-fonts";
          version = "1.0";
          inherit src;
          installPhase = ''
            mkdir -p $out/share/fonts/truetype
            find "$src/Windows Fonts" -type f \( -iname '*.ttf' -o -iname '*.ttc' \) -exec cp {} $out/share/fonts/truetype/ \;
          '';
          meta = with pkgs.lib; {
            description = "Collection of Windows system fonts";
            license = licenses.unfree;
            platforms = platforms.all;
          };
        };

        default = pkgs.symlinkJoin {
          name = "font-collection";
          paths = [
            centuryGothicPro
            sanFranciscoFamily
            windowsFonts
          ];
          meta = with pkgs.lib; {
            description = "Complete font collection (Century Gothic Pro + San Francisco family + Windows Fonts)";
            license = licenses.unfree;
            platforms = platforms.all;
          };
        };
      };
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        mkFontPkgs pkgs self
      );

      nixosModules.default =
        { pkgs, ... }:
        let
          fontPkgs = import self.inputs.nixpkgs {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        in
        {
          fonts.packages = [ (mkFontPkgs fontPkgs self).default ];
        };
    };
}
