{
  description = "Rust development template";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # polkadot-nix.url = "github:andresilva/polkadot.nix/519dfa2105e35544c244fa19044ce4e1e9a980bf";
    polkadot-nix.url = "github:andresilva/polkadot.nix";
    zombienet.url = "github:anstylian/zombienet";
    rust-overlay.url = "github:oxalica/rust-overlay";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      rust-overlay,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./nix/lib.nix
        ./nix/pkgs
        ./nix/devshell.nix
        ./nix/formatting.nix
        ./nix/git-hooks.nix
      ];

      perSystem =
        { system, ... }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };
        };
    };
}
