{
  network = {
    pkgs = import (fetchTarball "https://github.com/knarkzel/nixpkgs/archive/043de04db8a6b0391b3fefaaade160514d866946.tar.gz") {};
  };
  
  oddharaldxyz = { modulesPath, lib, name, ... }: {
    imports = [
      (modulesPath + "/virtualisation/openstack-config.nix")
    ];

    networking.hostName = name;
    system.stateVersion = "22.05";
    deployment.targetUser = "root";
    deployment.targetHost = "oddharald.xyz";

    networking.firewall.allowedTCPPorts = [ 80 ];
    services.nginx = {
      enable = true;
      virtualHosts.default = {
        default = true;
        locations."/".return = "200 \"Welcome to oddharald.xyz!\"";
      };
    };
  };
}
