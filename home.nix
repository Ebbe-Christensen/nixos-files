# home.nix
# Home Manager configuration for the 'user' user.
# This file defines user-specific packages, programs, and settings.

{ config, pkgs, ... }:

{
  # Set the Home Manager state version. This is crucial for migrations.
  # Set it to the NixOS release version you are currently using, or your first Home Manager install.
  home.stateVersion = "25.05"; # IMPORTANT: Ensure this matches your system.stateVersion or is a previous version.

  # Define packages to be installed in the user's profile.
  home.packages = with pkgs; [
    easyeffects
    waybar
    wofi
    mako
    alacritty
    kitty
    grim
    slurp
    wl-clipboard
    swaylock-effects # Used by swayidle for locking.
    swww
    hyprpicker
    nwg-look
    neofetch
    htop
    btop
    lazygit
    vscode
    steam # The client binary, while programs.steam.enable is system-wide.
    heroic
    prism-launcher
    gamemode # The client binary for user interaction.
    font-manager
    thunar
  ];

  # Configure Fish shell via Home Manager.
  programs.fish = {
    enable = true;
    # Add any Fish-specific configurations here, e.g.,
    # shellAliases = {
    #   ll = "ls -l";
    # };
  };

  # Configure Zsh via Home Manager.
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      # Other Oh My Zsh options can go here, e.g.,
      # plugins = [ "git" "z" ];
      # theme = "agnoster";
    };
    # Add any Zsh-specific configurations here, e.g.,
    # shellAliases = {
    #   l = "ls -la";
    # };
  };

  # Configure swayidle via Home Manager.
  services.swayidle = {
    enable = true;
    settings = [
      { timeout = 300; command = "${pkgs.swaylock-effects}/bin/swaylock -f"; }
      { timeout = 600; command = "systemctl suspend"; }
      { resumeCommand = "hyprctl dispatch dpms on"; }
    ];
  };

  # Set user-specific environment variables.
  home.sessionVariables = {
    GTK_THEME = "Catppuccin-Mocha-Compact-Lavender-Dark";
  };

  # Other Home Manager options for dotfiles, services, etc.
  # home.file.".config/hypr/hyprland.conf".source = ./hyprland/hyprland.conf;
  # home.file.".config/waybar/config".source = ./waybar/config;
  # home.file.".config/mako/config".source = ./mako/config;
}
