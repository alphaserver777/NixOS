{ pkgs, ... }:

{
  programs.ranger = {
    enable = true;
    mappings = {
      "." = "fzf_select";
      e = "edit";

      E = "shell viewnior %f";

      ec = "compress";
      ex = "extract";

    };

    settings = {
      preview_images = true;
      preview_images_method = "ueberzug";
      draw_borders = true;
      w3m_delay = 0;
      show_hidden = true; # Добавляем эту строку
    };

    extraConfig = ''
      default_linemode devicons2
      '';

    plugins = [
    {
      name = "ranger-archives";
      src = builtins.fetchGit {
        url = "https://github.com/maximtrp/ranger-archives";
        ref = "master";
        rev = "b4e136b24fdca7670e0c6105fb496e5df356ef25";
      };
    }
    {
      name = "ranger-devicons2";
      src = builtins.fetchGit {
        url = "https://github.com/cdump/ranger-devicons2";
        ref = "master";
        rev = "94bdcc19218681debb252475fd9d11cfd274d9b1";
      };
    }
    {
      name = "ranger_tmux";
      src = builtins.fetchGit {
        url = "https://github.com/joouha/ranger_tmux";
        ref = "master";
        rev = "05ba5ddf2ce5659a90aa0ada70eb1078470d972a";
      };
    }
    ];
  };

  home.file.".config/ranger/commands.py".text = ''
from ranger.api.commands import Command
import subprocess
import os.path

class fzf_select(Command):
    """
    :fzf_select

    Find a file using fzf.
    With a prefix argument select only directories.
    See: https://github.com/junegunn/fzf/wiki/Examples#ranger
    """
    def execute(self):
        if self.quantifier:
            # match only directories
            command="find -L . \( -path '*/\.*' -o -fstype 'dev' -o -fstype 'proc' \) -prune -o -type d -print 2> /dev/null | sed 1d | cut -b3- | ${pkgs.fzf}/bin/fzf +m"
        else:
            # match files and directories
            command="find -L . \( -path '*/\.*' -o -fstype 'dev' -o -fstype 'proc' \) -prune -o -print 2> /dev/null | sed 1d | cut -b3- | ${pkgs.fzf}/bin/fzf +m"
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip())
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)
  '';
}
