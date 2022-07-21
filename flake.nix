{
  description = "Knarkzel's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay, emacs-overlay, ... } @ inputs: {
    nixosConfigurations."odd" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix # System configuration
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            rust-overlay.overlay
            emacs-overlay.overlay
          ];
        })
      ];
    };
  };
}
