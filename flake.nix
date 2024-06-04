{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  outputs = _: {
    nixosModules = {
      diskix = import ./modules/nixos;
    };
  };
}
