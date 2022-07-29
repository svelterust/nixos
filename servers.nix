let
  pkgs = import (fetchTarball "https://github.com/knarkzel/nixpkgs/archive/043de04db8a6b0391b3fefaaade160514d866946.tar.gz") {};
  paste = fetchTarball {
    url = "https://github.com/JJJollyjim/nixos-flask-example/archive/refs/heads/master.tar.gz";
    sha256 = "02j802chsba7q4fmd6mzk59x1gywdpm210x1m4l44c219bxapl4r";
  };
in {
  network.pkgs = pkgs;

  oddharaldxyz = {
    lib,
    name,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/virtualisation/openstack-config.nix")
      "${paste}/service.nix"
    ];

    # Morph options
    deployment.targetUser = "root";
    deployment.targetHost = "oddharald.xyz";

    # Environment
    networking.hostName = name;
    system.stateVersion = "22.05";

    # oddharald.xyz
    networking.firewall.allowedTCPPorts = [80 8080];
    services.nginx = {
      enable = true;
      virtualHosts."oddharald.xyz" = {
        root = "/var/oddharald.xyz";
      };
    };

    # paste service
    services.paste.enable = true;
  };
}
