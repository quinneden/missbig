{
  description = "Example NixOS deployment via NixOS-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    lix-module,
    disko,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        lix-module.overlays.default
      ];
    };
  in {
    nixosConfigurations.missBig = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs pkgs system;};
      modules = [
        lix-module.nixosModules.default
        ./networks.nix
        ({
          modulesPath,
          inputs,
          config,
          lib,
          pkgs,
          ...
        }: {
          imports = [
            "${modulesPath}/installer/scan/not-detected.nix"
            disko.nixosModules.disko
          ];

          disko.devices = import ./single-gpt-disk-fullsize-ext4.nix "/dev/sda";

          boot = {
            loader.systemd-boot.enable = true;
            loader.efi.canTouchEfiVariables = true;
            kernelPackages = pkgs.linuxPackages_latest;
            kernelModules = ["88XXau"];
            initrd.availableKernelModules = ["88XXau" "xhci_pci" "ahci" "sd_mod"];
            extraModulePackages = [config.boot.kernelPackages.rtl88xxau-aircrack];
          };

          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };

          networking = {
            wireless.networks.Edenfield = {
              psk = "Eden2002!";
            };
            networkmanager = {
              enable = true;
            };
          };

          users.users.root = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyYkP65U0LY+BmH8vro7jGd1BZA4WaKxTr1ygB6ynRx quinn@nixos-macmini"
            ];
            password = "cbroot";
          };

          nixpkgs.hostPlatform = "x86_64-linux";
          powerManagement.cpuFreqGovernor = "ondemand";
          hardware.cpu.intel.updateMicrocode = true;
          hardware.enableRedistributableFirmware = true;
          networking.hostName = "missbig";

          system.stateVersion = "24.11";
        })
      ];
    };
  };
}
