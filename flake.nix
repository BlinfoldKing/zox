{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , zig-overlay
    , ...
    } @inputs:
    let
      inherit (self) outputs;
    in
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; overlays = [ zig-overlay.overlays.default ]; };
    in
    {
      devShells.default = with pkgs; mkShell rec {
        buildInputs = [
          zigpkgs.master
          zls
        ];
      };
    });
}
