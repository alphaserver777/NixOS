{ lib, ... }:

{
  environment.sessionVariables = rec {
    TERMINAL = "alacritty";
    EDITOR = "nvim";
    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = lib.concatStringsSep ":" [ XDG_BIN_HOME "$PATH" ];
  };
}
