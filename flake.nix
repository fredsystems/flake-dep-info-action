{
  description = "flake-dep-info-action";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    precommit-base = {
      url = "github:fredsystems/pre-commit-checks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      precommit-base,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        precommitCheck = precommit-base.lib.mkCheck {
          inherit system;
          src = ./.;

          extraExcludes = [
            "^dist/"
            "^CHANGELOG\\.md$"
          ];

          check_javascript = true;
          javascript = {
            enableBiome = true;
            enableTsc = true;
            tsConfig = "tsconfig.json";
          };
        };
      in
      {
        checks = {
          pre-commit-check = precommitCheck;
        };

        devShell = pkgs.mkShell {
          name = "flake-dep-info-action";
          buildInputs =
            precommitCheck.enabledPackages
            ++ (with pkgs; [
              typescript-go
              fd
              git
              nodejs_24
              npm-check
            ]);

          # npm forces output that can't possibly be useful to stdout so redirect
          # stdout to stderr
          shellHook = ''
            ${precommitCheck.shellHook}
            npm install --no-fund 1>&2
          '';
        };
      }
    );
}
