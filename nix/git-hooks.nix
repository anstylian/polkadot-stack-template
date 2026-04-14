{ inputs, ... }:

{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    let
      rustToolchainStable = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;

      rustHookPackages = [
        rustToolchainStable
        pkgs.pkg-config
        pkgs.openssl
      ];

      # Prefetch cargo dependencies for sandbox builds
      cargoDeps =
        if builtins.pathExists ../Cargo.lock then
          pkgs.rustPlatform.importCargoLock {
            lockFile = ../Cargo.lock;
            outputHashes = {
              "pallet-revive-proc-macro-0.7.1" = "sha256-UOD29/7fEc1z5E2LybtQ9V+CFNNvDaFmCRPytei+wtA=";
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

      cargoCheckWrapper = pkgs.writeShellScript "cargo-check-wrapper" ''
        export PATH=${rustToolchainStable}/bin:$PATH
        export OPENSSL_NO_VENDOR=1
        export OPENSSL_LIB_DIR=${pkgs.lib.getLib pkgs.openssl}/lib
        export OPENSSL_DIR=${pkgs.lib.getDev pkgs.openssl}
        export SKIP_PALLET_REVIVE_FIXTURES=1
        exec ${rustToolchainStable}/bin/cargo check --all-targets --all-features "$@"
      '';

      cargoTestWrapper = pkgs.writeShellScript "cargo-test-wrapper" ''
        export PATH=${rustToolchainStable}/bin:$PATH
        export OPENSSL_NO_VENDOR=1
        export OPENSSL_LIB_DIR=${pkgs.lib.getLib pkgs.openssl}/lib
        export OPENSSL_DIR=${pkgs.lib.getDev pkgs.openssl}
        export SKIP_PALLET_REVIVE_FIXTURES=1
        exec ${rustToolchainStable}/bin/cargo test "$@"
      '';

      clippyWrapper = pkgs.writeShellScript "cargo-clippy-wrapper" ''
        export PATH=${rustToolchainStable}/bin:$PATH
        export OPENSSL_NO_VENDOR=1
        export OPENSSL_LIB_DIR=${pkgs.lib.getLib pkgs.openssl}/lib
        export OPENSSL_DIR=${pkgs.lib.getDev pkgs.openssl}
        export SKIP_PALLET_REVIVE_FIXTURES=1
        exec ${rustToolchainStable}/bin/cargo clippy --offline --all-features --all-targets -- -D warnings "$@"
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
              package = rustToolchainStable;
              entry = "${cargoCheckWrapper}";
              extraPackages = rustHookPackages;
            };

            cargo-test = {
              enable = true;
              name = "cargo test";
              entry = "${cargoTestWrapper}";
              files = "\\.rs$";
              pass_filenames = false;
              extraPackages = rustHookPackages;
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
              entry = "${clippyWrapper}";
              extraPackages = rustHookPackages;
              packageOverrides = {
                cargo = rustToolchainStable;
                clippy = rustToolchainStable;
              };
              settings = {
                allFeatures = true;
                denyWarnings = true;
                extraArgs = "--all-targets";
              };
            };

            # secret detection
            ripsecrets = {
              enable = true;
              excludes = [
                "^target/"
                "^result(/|$)"
                "^\\.direnv/"
                "^web/\\.papi/descriptors/dist/"
                "^web/\\.papi/metadata/"
                "^web/node_modules/"
                "^contracts/.*/node_modules/"
              ];
            };
            trufflehog = {
              enable = true;
              excludes = [
                "^target/"
                "^result(/|$)"
                "^\\.direnv/"
                "^web/\\.papi/descriptors/dist/"
                "^web/\\.papi/metadata/"
                "^web/node_modules/"
                "^contracts/.*/node_modules/"
              ];
            };

            # spell checker
            typos = {
              enable = true;
              settings.config = {
                # Ignore hash-like alphanumeric identifiers and addresses.
                # Keep the threshold low enough to skip short IDs like `I6f9v7emp7t5ba`.
                # See: https://github.com/crate-ci/typos#configuration
                default = {
                  extend-ignore-re = [ "([a-zA-Z0-9]{12,})" ];
                  extend-ignore-words-re = [ "inherents" ];
                };
              };
            };

            # toml
            taplo.enable = true;

            # yaml
            yamllint = {
              enable = true;
              settings.configData = ''
                extends: default
                rules:
                  document-start: disable
                  line-length: disable
              '';
            };
          };
        };
      };
    };
}
