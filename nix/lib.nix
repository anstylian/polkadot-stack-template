_: {
  perSystem =
    { pkgs, ... }:
    let
      # Stable Rust: used for development, builds, tests and linting.
      rustToolchainStable = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;
    in
    {
      _module.args = {
        inherit rustToolchainStable;
      };
    };
}
