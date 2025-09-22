{ lib, pkgs, user, ... }: {
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    users.${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "syncthing" "docker" "audio" "video" "kvm" ];
    };
  };

  # Отключение запроса пароля для sudo
  security.sudo.wheelNeedsPassword = lib.mkDefault false;

}

#services.getty.autologinUser = user;
