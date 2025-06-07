# configuration.nix
# NixOS configuration for an AMD-based developer/gamer machine using Hyprland.
# Now integrating Home Manager for user-specific configurations.

{ config, pkgs, home-manager, ... }: # <-- 'home-manager' added here

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

in
{
  ############################################
  # 1. Boot & Hardware
  ############################################

  imports = [
    ./hardware-configuration.nix
    # Enable Home Manager NixOS module. This will import your user's home.nix.
    # Ensure the home-manager channel is added and updated for this to be found.
    home-manager.nixosModules.home-manager
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
  home-manager.users.user = { pkgs, ... }: {
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

  # These programs are now managed by Home Manager in home.nix for the user.
  # programs.fish.enable = true;
  # programs.zsh.enable = true;
  # programs.zsh.ohMyZsh.enable = true;

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

  # Swayidle is now managed by Home Manager in home.nix.
  # services.swayidle.enable = true;
  # services.swayidle.settings = [
  #   { timeout = 300; command = "${pkgs.swaylock-effects}/bin/swaylock -f"; }
  #   { timeout = 600; command = "systemctl suspend"; }
  #   { resumeCommand = "hyprctl dispatch dpms on"; }
  # ];

  ############################################
  # 8. Theming and Aesthetics
  ############################################

  fonts.fonts = with pkgs; [
    fira-code
    jetbrains-mono
  ];

  # GTK_THEME is now managed by Home Manager in home.nix for the user.
  # environment.variables = {
  #   GTK_THEME = "Catppuccin-Mocha-Compact-Lavender-Dark";
  # };

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
