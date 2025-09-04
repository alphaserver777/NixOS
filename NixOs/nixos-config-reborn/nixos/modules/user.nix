{ pkgs, user, ... }: {
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    users.${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "syncthing"];
    };
  };

# Отключение запроса пароля для sudo
  security.sudo.wheelNeedsPassword = false;

                     }

#services.getty.autologinUser = user;

