{ inputs, ... }:

{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { pkgs, rustToolchainNightly, ... }:
    let
      # Prefetch cargo dependencies for sandbox builds
      cargoDeps =
        if builtins.pathExists ../Cargo.lock then
          pkgs.rustPlatform.importCargoLock {
            lockFile = ../Cargo.lock;
            outputHashes = {
              "pallet-revive-proc-macro-0.7.1" = pkgs.lib.fakeHash;
            };
          }
        else
          null;

      # Wrapper script for cargo-audit that skips in Nix sandbox (no network access)
      cargoAuditWrapper = pkgs.writeShellScript "cargo-audit-wrapper" ''
        if [ -n "$NIX_BUILD_TOP" ]; then
          echo "Skipping cargo-audit in Nix sandbox (requires network access)"
          exit 0
        fi
        exec ${pkgs.cargo-audit}/bin/cargo-audit audit
      '';
    in
    {
      # To configure git hooks after you change this file, run:
      # $ nix develop -c pre-commit run -a
      pre-commit = {
        check.enable = true;
        settings = {
          settings.rust.check = pkgs.lib.optionalAttrs (cargoDeps != null) {
            inherit cargoDeps;
          };
          hooks = {
            # markdown
            mdsh.enable = true;

            # shell
            shellcheck.enable = true;

            # nix
            nixfmt.enable = true;
            flake-checker.enable = true;
            statix = {
              enable = true;
              settings = {
                ignore = [ ".direnv/*" ];
              };
            };

            # Rust
            cargo-check = {
              enable = true;
              package = rustToolchainNightly;
              entry = "${rustToolchainNightly}/bin/cargo check --all-targets --all-features";
              extraPackages = [ rustToolchainNightly ];
            };

            cargo-test = {
              enable = true;
              name = "cargo test";
              entry = "${rustToolchainNightly}/bin/cargo test";
              files = "\\.rs$";
              pass_filenames = false;
              extraPackages = [ rustToolchainNightly ];
            };

            # Check for security vulnerabilities
            # Skipped in Nix sandbox (requires network access to fetch advisory database)
            cargo-audit = {
              enable = true;
              name = "cargo-audit";
              entry = "${cargoAuditWrapper}";
            };

            # Check for unused dependencies
            cargo-machete = {
              enable = true;
              name = "cargo-machete";
              entry = "${pkgs.cargo-machete}/bin/cargo-machete";
            };

            # Rust linter
            clippy = {
              enable = true;
              packageOverrides = {
                cargo = rustToolchainNightly;
                clippy = rustToolchainNightly;
              };
              settings = {
                allFeatures = true;
                denyWarnings = true;
                extraArgs = "--all-targets";
              };
            };

            # secret detection
            ripsecrets.enable = true;
            trufflehog.enable = true;

            # spell checker
            typos = {
              enable = true;
              settings.config = {
                # Ignore words matching long alphanumeric patterns (hashes, addresses)
                # This regex matches strings with 16+ alphanumeric chars (adjust as needed)
                # See: https://github.com/crate-ci/typos#configuration
                default.extend-ignore-re = [ "([a-zA-Z0-9]{16,})" ];
              };
            };

            # toml
            taplo.enable = true;

            # yaml
            yamllint.enable = true;
          };
        };
      };
    };
}
