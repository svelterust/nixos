let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/e3583ad6e533a9d8dd78f90bfa93812d390ea187.tar.gz") {};
  fish = fetchTarball {
    url = "https://git.sr.ht/~knarkzel/fish/archive/5a671a1195b1979fdb20bebf9fe4e3b54d722043.tar.gz";
    sha256 = "1kv0xc5v8vay68sg8ih7r0nsnf68nx9jrv7ny28i49s0x7dxsl4j";
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
      firewall.allowedTCPPorts = [80 443];
    };

    # fish service
    services.fish = {
      enable = true;
      port = 5000;
    };

    # mattermost service
    services.mattermost = {
      enable = true;
      siteUrl = "https://chat.oddharald.xyz";
    };

    # acme, aka. ssl
    security.acme = {
      acceptTerms = true;
      defaults.email = "knarkzel@gmail.com";
    };
    
    # nginx service
    services.nginx = {
      enable = true;

      # Use recommended settings
      recommendedGzipSettings = lib.mkDefault true;
      recommendedOptimisation = lib.mkDefault true;
      recommendedProxySettings = lib.mkDefault true;
      recommendedTlsSettings = lib.mkDefault true;

      # Virtual hosts
      virtualHosts = {
        "oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/oddharald.xyz";
        };
        
        "fish.oddharald.xyz" =  {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:5000";
          };
        };
        
        "chat.oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://0.0.0.0:8065";
          };
        };
      };
    };
  };
}
