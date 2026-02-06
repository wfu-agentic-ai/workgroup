{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      # Core packages for academic work
      corePackages = with pkgs; [
        R
        git
        pandoc
        python3
        quarto
        radian
        typst
      ];

      # R packages for data analysis
      rPackages = with pkgs; [
        # rPackages.tidyverse
      ];

      # Python packages for computational work
      pythonPackages = with pkgs; [
        # python3Packages.pandas
      ];

      # Development tools
      devTools = with pkgs; [
        direnv
      ];

      allPackages = corePackages ++ rPackages ++ pythonPackages ++ devTools;
    in {
      devShell = pkgs.mkShell {
        buildInputs = allPackages;

        shellHook = ''
          echo "Academic project environment loaded"
          echo "Core tools: git, pandoc, quarto"
          echo "Use 'direnv allow' to auto-load this environment"
        '';
      };
    });
}
