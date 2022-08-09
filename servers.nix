let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/e3583ad6e533a9d8dd78f90bfa93812d390ea187.tar.gz") {};
  fish = fetchTarball {
    url = "https://git.sr.ht/~knarkzel/fish/archive/e96951531dce452be8f1dd7357f81b69445285a.tar.gz";
    sha256 = "02kwvmzkka0gip36l099gdqmal4bxbzr9agyr6bv8k1j4vbab44h";
  };
in {
  network.pkgs = pkgs;

  oddharaldxyz = {
    lib,
    name,
    modulesPath,
    ...
  }: {
    # environment and imports
    system.stateVersion = "22.05";
    imports = [
      (modulesPath + "/virtualisation/openstack-config.nix")
      "${fish}/service.nix"
    ];

    # morph options
    deployment = {
      targetUser = "root";
      targetHost = "oddharald.xyz";
    };

    # networking
    networking = {
      hostName = name;
      firewall.allowedTCPPorts = [80 443];
    };

    # acme, aka. ssl
    security.acme = {
      acceptTerms = true;
      defaults.email = "knarkzel@gmail.com";
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

    # miniflux
    services.miniflux = {
      enable = true;
      adminCredentialsFile = /etc/nixos/miniflux-admin-credentials;
    };

    # nginx service
    services.nginx = {
      enable = true;

      # use recommended settings
      recommendedGzipSettings = lib.mkDefault true;
      recommendedOptimisation = lib.mkDefault true;
      recommendedProxySettings = lib.mkDefault true;
      recommendedTlsSettings = lib.mkDefault true;

      # virtual hosts
      virtualHosts = {
        "fish.oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:5000";
          };
        };

        "rss.oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:8080";
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
