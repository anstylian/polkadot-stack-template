{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        eth-rpc = pkgs.callPackage ./eth-rpc.nix { };
      };
    };
}
