{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        eth-rpc = pkgs.callPackage ./eth-rpc.nix { };
        psvm = pkgs.callPackage ./psvm.nix { };
      };
    };
}
