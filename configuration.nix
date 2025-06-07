# configuration.nix
# NixOS configuration for an AMD-based developer/gamer machine using Hyprland.
# Now integrating Home Manager for user-specific configurations.

{ config, pkgs, lib, ... }: # 'home-manager' is no longer needed in arguments

let
  # Custom scripts defined here for robustness, referenced via the Nix store.
  midiScript = pkgs.writeScriptBin "midi.py" ''
    #!${pkgs.python3}/bin/python3
    # Your midi.py script content goes here.
    # Example:
    # import sys
    # print("MIDI Python script running!", file=sys.stderr)
    # import time
    # try:
    #     while True:
    #         time.sleep(1)
    # except KeyboardInterrupt:
    #     print("MIDI Python script stopping.", file=sys.stderr)
    #     pass
  '';

  combineSinkScript = pkgs.writeScriptBin "combine-sink.sh" ''
    #!/bin/sh
    # Your combine-sink.sh script content goes here.
    # Example:
    # pw-cli create-node adapter '{factory.name=support.null-audio-sink node.name=CombinedSink media.class=Audio/Sink audio.channels=2 audio.position=FL,FR}'
  '';

  # Explicitly fetch the Home Manager module from its tarball.
  # This makes the home-manager module available directly, avoiding channel issues.
  # IMPORTANT: Ensure 'release-25.05' matches your system.stateVersion.
  homeManagerModule = import (builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz");

in
{
  ############################################
  # 1. Boot & Hardware
  ############################################

  imports = [
    ./hardware-configuration.nix
    # Enable Home Manager NixOS module using the explicitly fetched module.
    homeManagerModule.nixosModules.home-manager
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  # rEFInd can chainload systemd-boot.

  fileSystems."/" = {
    # IMPORTANT: Verify this path with your hardware-configuration.nix or `lsblk -f` for your unencrypted root.
    device = "/dev/disk/by-uuid/YOUR-UNENCRYPTED-ROOT-UUID-HERE";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "space_cache=v2"];
  };

  ############################################
  # 2. Networking
  ############################################

  networking.hostName = "nix-pc";
  networking.networkmanager.enable = true;

  ############################################
  # 3. Localization
  ###########################################

  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  # Override specific locale categories for Finnish formatting.
  i18n.extraLocaleSettings = {
    LC_TIME = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fi";
  };

  ############################################
  # 4. User Configuration
  ############################################

  users.users.user = {
    isNormalUser = true;
    description = "Main User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    uid = 3000;
    # Shell is now managed by Home Manager for the user, but we can keep this for system-wide default.
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false; # Disables password for sudo (wheel group).

  # Define Home Manager configuration for the 'user'.
  # This imports the configuration from ./home.nix.
  # We pass pkgs and lib explicitly here, as required by home-manager's user module.
  home-manager.users.user = { pkgs, lib, ... }: {
    imports = [ ./home.nix ];
  };

  ############################################
  # 5. AMD GPU Drivers & ROCm
  ############################################

  services.xserver.videoDrivers = [ "amdgpu" ]; # Mostly for X11, but harmless for Wayland.

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      mesa
      rocm-opencl-runtime
      rocmPackages.rocminfo
    ];
  };

  hardware.opengl.extraPackages32 = with pkgs; [ libva ];

  ############################################
  # 6. Sound, Pipewire, Bluetooth
  ############################################

  sound.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  security.rtkit.enable = true; # Enabled for better real-time audio performance with PipeWire.

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  ############################################
  # 7. Hyprland and Desktop Environment
  ############################################

  programs.hyprland.enable = true;

  services.dbus.enable = true;
  services.xserver.enable = false; # Crucial: Disables X server for Wayland setup.

  # System-wide packages - typically only essential system utilities and libraries.
  # User-specific applications are now handled by Home Manager in home.nix.
  environment.systemPackages = with pkgs; [
    git # Often needed by system tools/scripts or other users.
    nodejs # Development runtimes often used system-wide for various tools.
    npm
    pnpm
    python3
    nix-direnv # NixOS management tools.
    nix-flatpak
    devenv
    disko
    libva # Graphics stack dependencies.
    libva-utils
    vulkan-tools
    vulkan-validation-layers
    catppuccin-gtk.mochi.compact.lavender.dark # GTK theme, needed system-wide for consistency.
  ];

  programs.steam.enable = true;
  programs.gamemode.enable = true; # Enabled system-wide, but client binary might be in Home Manager.

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "Hyprland";
        user = "user";
      };
    };
    # Autologin is disabled. You will be prompted for a password.
  };

  services.seatd.enable = true;

  ############################################
  # 8. Theming and Aesthetics
  ############################################

  fonts.fonts = with pkgs; [
    fira-code
    jetbrains-mono
  ];

  ############################################
  # 9. NFS Mounts
  ############################################

  fileSystems."/mnt/Koulu" = {
    device = "192.168.1.2:/mnt/pool/Ebbe/Koulu";
    fsType = "nfs";
    options = ["rw" "x-systemd.automount" "noatime" "uid=3000" "gid=3000"];
  };

  fileSystems."/mnt/backup" = {
    device = "192.168.1.2:/mnt/pool/Ebbe/backup";
    fsType = "nfs";
    options = ["rw" "x-systemd.automount" "noatime" "uid=3000" "gid=3000"];
  };

  fileSystems."/mnt/ebbe" = {
    device = "192.168.1.2:/mnt/pool/Ebbe/ebbe";
    fsType = "nfs";
    options = ["rw" "x-systemd.automount" "noatime" "uid=3000" "gid=3000"];
  };

  fileSystems."/mnt/MakeMKV" = {
    device = "192.168.1.2:/mnt/pool/MakeMKV";
    fsType = "nfs";
    options = ["rw" "x-systemd.automount" "noatime" "uid=3000" "gid=3000"];
  };

  ############################################
  # 10. Backup System: Borg
  ############################################

  services.borgbackup.jobs."home-backup" = {
    paths = [ "/home/user" ];
    repo = "user@192.168.1.2:/mnt/pool/Ebbe/backup";
    encryption.mode = "repokey";
    compression = "zstd";
    startAt = "daily";
  };

  ############################################
  # 11. Custom Services
  ############################################

  systemd.user.services.midi-python = {
    description = "MIDI Audio Controller";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${midiScript}/bin/midi.py";
      Restart = "on-failure";
    };
  };

  systemd.user.services.combine-sink = {
    description = "Custom combined audio sink setup";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${combineSinkScript}/bin/combine-sink.sh";
      Restart = "on-failure";
    };
  };

  ############################################
  # 12. System Settings
  ############################################

  system.stateVersion = "25.05";
}
