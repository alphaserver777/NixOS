{ config, lib, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases =
      let
      flakeDir = "~/flake";
    in
    {
      nrs = "sudo nixos-rebuild switch --flake .#$(hostname)";
      nrsx = "sudo env NIXOS_SECRETS_PATH=/home/admsys/Nixos/nixos-config/secrets.nix nixos-rebuild switch --flake /home/admsys/Nixos/nixos-config#$(hostname) --impure";
      upd = "ip a";
      hms = "home-manager switch --flake ~/Nixos/nixos-config/#admsys";
      pkgs = "nvim ${flakeDir}/nixos/packages.nix";

      r = "ranger";
      v = "nvim";
      se = "sudoedit";
      microfetch = "microfetch && echo";

      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";

      ".." = "cd ..";
    };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
# Start Tmux automatically if not already running. No Tmux in TTY
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux attach-session -t default || tmux new-session -s default
          fi

# Start UWSM
          if uwsm check may-start > /dev/null && uwsm select; then
            exec systemd-cat -t uwsm_start uwsm start default
              fi
      '')

      (lib.mkOrder 1500 ''
        # Стандартное редактирование командной строки, как в Bash.
        # Этот блок должен быть последним: дополнения Zsh меняют назначения клавиш.
        bindkey -e
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[5D' backward-word
        bindkey '^[[5C' forward-word
      '')
    ];
  };
}
