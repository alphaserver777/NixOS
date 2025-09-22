{ config, ... }: {
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

    initContent = ''
# Start Tmux automatically if not already running. No Tmux in TTY
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux attach-session -t default || tmux new-session -s default
          fi

# Start UWSM
          if uwsm check may-start > /dev/null && uwsm select; then
            exec systemd-cat -t uwsm_start uwsm start default
              fi
              '';
  };
                 }
