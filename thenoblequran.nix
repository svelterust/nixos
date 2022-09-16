let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/e3583ad6e533a9d8dd78f90bfa93812d390ea187.tar.gz") {};
  quran = fetchTarball {
    url = "https://git.sr.ht/~knarkzel/quran/archive/e6ba3a0071a5ea5495d56aea45274858a4614c6c.tar.gz";
    sha256 = "0pa5520mvc0k84saahns3fbjdqzlay5j5yv0996mzn0adhkbr0rx";
  };
in {
  network.pkgs = pkgs;

  thenoblequran = {
    lib,
    name,
    modulesPath,
    ...
  }: {
    # environment and imports
    system.stateVersion = "22.05";
    imports = [
      (modulesPath + "/virtualisation/openstack-config.nix")
      "${quran}/service.nix"
    ];

    # morph options
    deployment = {
      targetUser = "root";
      targetHost = "thenoblequran.xyz";
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

    # quran
    services.quran = {
      enable = true;
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
        "thenoblequran.xyz" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://0.0.0.0:8080";
          };
        };
      };
    };
  };
}
