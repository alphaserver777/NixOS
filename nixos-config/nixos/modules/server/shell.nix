{ pkgs, user, ... }:
let
  zshrcText = ''
    # Minimal server zsh profile
    export STARSHIP_CONFIG=/etc/starship.toml

    if [[ $TERM != "dumb" ]] && command -v starship >/dev/null 2>&1; then
      eval "$(starship init zsh)"
    fi
  '';
in {
  environment.systemPackages = [ pkgs.starship ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  environment.etc."starship.toml".text = ''
    add_newline = true

    [hostname]
    ssh_only = false
    format = "[$ssh_symbol$hostname]($style) "
    style = "bold purple"

    [character]
    success_symbol = "[ & ](bold green)"
    error_symbol = "[ & ](bold red)"

    [username]
    show_always = true
    format = "[$user]($style)@"

    [directory]
    truncation_symbol = "…/"
  '';

  environment.etc."skel/.zshrc".text = zshrcText;

  system.activationScripts.serverZshrc = ''
    if [ -d /home/${user} ] && [ ! -e /home/${user}/.zshrc ]; then
      cp /etc/skel/.zshrc /home/${user}/.zshrc
      chown ${user}:users /home/${user}/.zshrc
    fi
  '';
}
