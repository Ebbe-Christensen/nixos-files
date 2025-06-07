# configuration.nix
# NixOS configuration for a secure, stylish, AMD-based developer/gamer machine using Hyprland.

{ config, pkgs, ... }:

{
  ############################################
  # 1. Boot & Hardware
  ############################################

  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.refind = {
    enable = true;
    version = "latest";
    useNvram = true;
  };

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/PUT-YOUR-UUID-HERE";
    preLVM = true;
  };

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
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
  ############################################

  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
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

  security.sudo.wheelNeedsPassword = false;

  ############################################
  # 5. AMD GPU Drivers & ROCm
  ############################################

  services.xserver.videoDrivers = [ "amdgpu" ];

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

    environment.etc."pipewire/pipewire-pulse.conf".source = "/home/user/.config/pipewire/pipewire-pulse.conf";

  ############################################
  # 7. Hyprland and Desktop Environment
  ############################################

  programs.hyprland.enable = true;

  services.dbus.enable = true;
  services.xserver.enable = false;

  environment.systemPackages = with pkgs; [
    easyeffects
    hyprland
    waybar
    rofi-wayland
    dunst
    alacritty
    kitty
    grim slurp wl-clipboard
    swaylock-effects swayidle
    hyprpaper hyprpicker nwg-look
    neofetch htop btop git lazygit direnv
    vscode nodejs npm pnpm python3
    fish starship oh-my-zsh
    steam heroic prism-launcher
    gamemode
    libva libva-utils vulkan-tools vulkan-validation-layers
    font-manager
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })

    # Hyprland must-haves
    mako
    wofi
    swww
    wlogout
    thunar

    # NixOS must-haves
    nix-direnv
    nix-flatpak
    devenv
    disko
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = true;

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Autologin to Hyprland
  services.getty.autoLogin.enable = true;
  services.getty.autoLogin.user = "user";

  services.seatd.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "Hyprland";
      user = "user";
    };
  };

  # Idle timeout and locking
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
    fira-code jetbrains-mono
  ];

  environment.variables = {
    GTK_THEME = "Catppuccin-Mocha-Compact-Lavender-Dark";
  };

  # You can optionally apply custom Hyprland configs in /home/user/.config/hypr/

  # Common keybindings for Hyprland (apply these in your hyprland.conf)
  # Application Launchers
  #   bind = SUPER, Return, exec, kitty
  #   bind = SUPER, D, exec, rofi -show drun
  #   bind = SUPER, E, exec, thunar
  #   bind = SUPER, B, exec, brave
  #   bind = SUPER, V, exec, cliphist list | rofi -dmenu | wl-copy
  #   bind = SUPER_SHIFT, Q, exec, wlogout

  # Window Management
  #   bind = SUPER, H, movefocus, l
  #   bind = SUPER, J, movefocus, d
  #   bind = SUPER, K, movefocus, u
  #   bind = SUPER, L, movefocus, r
  #   bind = SUPER_SHIFT, H, movewindow, l
  #   bind = SUPER_SHIFT, J, movewindow, d
  #   bind = SUPER_SHIFT, K, movewindow, u
  #   bind = SUPER_SHIFT, L, movewindow, r
  #   bind = SUPER, F, fullscreen
  #   bind = SUPER, Space, togglefloating
  #   bind = SUPER, Q, killactive
  #   bind = SUPER, A, togglespecialworkspace

  # Mouse Controls
  #   bindm = SUPER, mouse:272, movewindow
  #   bindm = SUPER, mouse:273, resizewindow
  #   bindm = SUPER, mouse:274, killactive
  #   bind = SUPER, mouse_up, exec, hyprctl dispatch opacityactive +0.05
  #   bind = SUPER, mouse_down, exec, hyprctl dispatch opacityactive -0.05

  # Workspace Management
  #   bind = SUPER, 1, workspace, 1
  #   bind = SUPER, 2, workspace, 2
  #   bind = SUPER, 3, workspace, 3
  #   bind = SUPER, 4, workspace, 4
  #   bind = SUPER, 5, workspace, 5
  #   bind = SUPER, 6, workspace, 6
  #   bind = SUPER, 7, workspace, 7
  #   bind = SUPER, 8, workspace, 8
  #   bind = SUPER, 9, workspace, 9
  #   bind = SUPER_SHIFT, 1, movetoworkspace, 1
  #   bind = SUPER_SHIFT, 2, movetoworkspace, 2
  #   bind = SUPER_SHIFT, 3, movetoworkspace, 3
  #   bind = SUPER_SHIFT, 4, movetoworkspace, 4
  #   bind = SUPER_SHIFT, 5, movetoworkspace, 5
  #   bind = SUPER_SHIFT, 6, movetoworkspace, 6
  #   bind = SUPER_SHIFT, 7, movetoworkspace, 7
  #   bind = SUPER_SHIFT, 8, movetoworkspace, 8
  #   bind = SUPER_SHIFT, 9, movetoworkspace, 9
  #   bind = SUPER, Tab, workspace, special

  # System Controls
  #   binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
  #   binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
  #   binde = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  #   binde = , XF86MonBrightnessUp, exec, brightnessctl set +10%
  #   binde = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

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
      ExecStart = "/home/user/scripts/midi.py";
      Restart = "on-failure";
    };
  };

  systemd.user.services.combine-sink = {
    description = "Custom combined audio sink setup";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "/home/user/.local/bin/combine-sink.sh";
      Restart = "on-failure";
    };
  };

  ############################################
  # 12. System Settings
  ############################################

  system.stateVersion = "25.05";
}
