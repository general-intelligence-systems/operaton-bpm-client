{
  description = "Operaton External Task Client for Ruby";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ruby
            bundler

            # toolchain for native gem extensions (e.g. bigdecimal)
            gcc
            gnumake
            pkg-config
            libyaml
            openssl
            zlib
          ];

          shellHook = ''
            export BUNDLE_PATH="$PWD/vendor/bundle"
            export BUNDLE_BIN="$PWD/vendor/bundle/bin"
            export PATH="$BUNDLE_BIN:$PATH"
          '';
        };
      });
}
