let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/e3583ad6e533a9d8dd78f90bfa93812d390ea187.tar.gz") {};
  fish = fetchTarball {
    url = "https://git.sr.ht/~knarkzel/fish/archive/ae8da8b3d54d0aa5b8d56c7511525a241875c4f6.tar.gz";
    sha256 = "0clhl68qffqwz1w2cwakhv9m0dawd21gmlmf523rq20nkjbhf013";
  };
  georust = fetchTarball {
    url = "https://git.sr.ht/~knarkzel/georust/archive/0661affe0c42364a31a75581c2bc12f6e05b9e6c.tar.gz";
    sha256 = "0f47mw7xahv0wkzrzljy4ci2rh6jy95dm334fp0va92pfi064cnd";
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
      "${georust}/service.nix"
    ];
    environment.systemPackages = with pkgs; [
      fd
      git
      ripgrep
      zip
      unzip
      file
      psmisc
      tldr
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
      georust = "http://0.0.0.0:9000";
    };

    # georust service
    services.georust = {
      enable = true;
      port = 9000;
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
        "oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/oddharald.xyz";
        };
        
        "crustyahh.xyz" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/crustyahh.xyz";
        };
        
        "fish.oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:5000";
          };
        };

        "georust.oddharald.xyz" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:9000";
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
