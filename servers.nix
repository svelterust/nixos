let
  pkgs = import (fetchTarball "https://github.com/knarkzel/nixpkgs/archive/043de04db8a6b0391b3fefaaade160514d866946.tar.gz") {};
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
    ];

    # Morph options
    deployment.targetUser = "root";
    deployment.targetHost = "oddharald.xyz";

    # Environment
    networking.hostName = name;
    system.stateVersion = "22.05";
    environment.systemPackages = with pkgs; [git];

    # oddharald.xyz
    networking.firewall.allowedTCPPorts = [80];
    services.nginx = {
      enable = true;
      virtualHosts."oddharald.xyz" = {
        root = "/var/oddharald.xyz";
      };
    };
  };
}
