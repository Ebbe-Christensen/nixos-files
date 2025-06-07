# configuration.nix
# NixOS configuration for an AMD-based developer/gamer machine using Hyprland.

{ config, pkgs, ... }:

let
  # Custom scripts defined here for robustness, referenced via the Nix store.
  midiScript = pkgs.writeScriptBin "midi.py" ''
    #!${pkgs.python3}/bin/python3
    # Your midi.py script content goes here.
  '';

  combineSinkScript = pkgs.writeScriptBin "combine-sink.sh" ''
    #!/bin/sh
    # Your combine-sink.sh script content goes here.
  '';

in
{
  ############################################
  # 1. Boot & Hardware
  ############################################

  imports = [
    ./hardware-configuration.nix
    # home-manager.nixosModules.home-manager # Uncomment if using Home Manager
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
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false; # Disables password for sudo (wheel group).

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

  environment.systemPackages = with pkgs; [
    easyeffects
    waybar
    wofi
    mako
    alacritty
    kitty
    grim slurp wl-clipboard
    swaylock-effects swayidle
    swww hyprpicker nwg-look
    neofetch htop btop git lazygit direnv
    vscode nodejs npm pnpm python3
    fish starship zsh
    steam heroic prism-launcher
    gamemode
    libva libva-utils vulkan-tools vulkan-validation-layers
    font-manager # Be aware of declarative config limitations with graphical font managers.
    thunar
    nix-direnv
    nix-flatpak
    devenv
    disko
    catppuccin-gtk.mochi.compact.lavender.dark
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = true;

  programs.steam.enable = true;
  programs.gamemode.enable = true;

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

  services.swayidle.enable = true;
  services.swayidle.settings = [
    { timeout = 300; command = "${pkgs.swaylock-effects}/bin/swaylock -f"; }
    { timeout = 600; command = "systemctl suspend"; }
    { resumeCommand = "hyprctl dispatch dpms on"; }
  ];

  ############################################
  # 8. Theming and Aesthetics
  ############################################

  fonts.fonts = with pkgs; [
    fira-code
    jetbrains-mono
  ];

  environment.variables = {
    GTK_THEME = "Catppuccin-Mocha-Compact-Lavender-Dark";
  };

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
