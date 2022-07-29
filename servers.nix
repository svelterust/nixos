let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/e3583ad6e533a9d8dd78f90bfa93812d390ea187.tar.gz") {};
  fish = fetchTarball {
    url = "https://git.sr.ht/~knarkzel/fish/archive/fd3a092bf6930536c191d84e55e991e9d3f05d44.tar.gz";
    sha256 = "0cxnx9s2ys7zn7qi0kl10c21b4dh7xgg6qkywpnssx1x9289vmrz";
  };
in {
  network.pkgs = pkgs;

  oddharaldxyz = {
    lib,
    name,
    modulesPath,
    ...
  }: {
    # Environment and imports
    system.stateVersion = "22.05";
    imports = [
      (modulesPath + "/virtualisation/openstack-config.nix")
      "${fish}/service.nix"
    ];

    # Morph options
    deployment = {
      targetUser = "root";
      targetHost = "oddharald.xyz";
    };

    # Networking
    networking = {
      hostName = name;
      firewall.allowedTCPPorts = [80];
    };

    # oddharald.xyz
    services.nginx = {
      enable = true;
      virtualHosts."oddharald.xyz" = {
        root = "/var/oddharald.xyz";
      };
      virtualHosts."fish.oddharald.xyz" =  {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
        };
      };
    };

    # fish service
    services.fish.enable = true;
  };
}
