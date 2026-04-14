{
  fetchFromGitHub,
  openssl,
  pkg-config,
  pkgs,
  protobuf,
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
  pname = "eth-rpc";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "paritytech";
    repo = "polkadot-sdk";
    tag = "polkadot-stable2603";
    hash = "sha256-2f3+/UejdTBt4/rhKP/jCS7JY7eeSLcOXiecWu47x+Y=";
  };

  cargoBuildFlags = [
    "--package"
    "pallet-revive-eth-rpc"
    "--bin"
    "eth-rpc"
  ];
  cargoTestFlags = cargoBuildFlags;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  nativeBuildInputs = [
    protobuf
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [ openssl ];
  doCheck = false;

  meta = {
    description = "Ethereum JSON-RPC adapter for pallet-revive";
    homepage = "https://github.com/paritytech/polkadot-sdk/tree/master/substrate/frame/revive/rpc";
  };
}
