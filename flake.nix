{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , ...
    } @inputs:
    let
      inherit (self) outputs;
    in
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.default = with pkgs; mkShell rec {
        buildInputs = [
          zig
          zls
        ];
      };
    });
}
