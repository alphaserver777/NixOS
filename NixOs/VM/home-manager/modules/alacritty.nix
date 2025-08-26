{config, pkgs, lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 1.0;

      font = {
        builtin_box_drawing = true;
        normal = {
	  family = "JetBrains Mono";
          style = lib.mkDefault "Bold";
        };
	size = lib.mkForce 10.0;
      };
    };
  };
}
