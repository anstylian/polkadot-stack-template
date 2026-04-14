{
  openssl,
  pkg-config,
  pkgs,
  rust-bin,
}:

let
  toolchain = rust-bin.fromRustupToolchainFile ../../rust-toolchain.toml;
  rustPlatform = pkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "psvm";
  version = "0.3.0";

  src = pkgs.fetchCrate {
    inherit pname version;
    hash = "sha256-518DmoZ82ojt/2r6UE0Si9DSYTts8Ei8VJPrmQ4EnKo=";
  };

  cargoHash = "sha256-kwo3NLp9BPInWkAPIKTMrQsl9G1MT2bZxSF4x0alBVo=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [ openssl ];
  doCheck = false;

  meta = {
    description = "CLI to manage Polkadot SDK crate version migrations";
    homepage = "https://crates.io/crates/psvm";
  };
}
