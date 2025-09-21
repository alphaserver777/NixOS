from ranger.api.commands import Command
import subprocess
import os.path

class search_content(Command):
    """
    :search_content <query>

    Searches for a string in all files in the current directory and shows the results in fzf.
    """
    def execute(self):
        if self.arg(1):
            query = self.rest(1)
            command = "tmux display-popup -E \"rg --line-number --no-heading --color=always '" + query + "' | @FZF_PATH@\""
            self.fm.execute_command(command, universal_newlines=True)
        else:
            self.fm.notify("Usage: search_content <query>", bad=True)

    def tab(self, tabnum):
        return self._tab_directory_content()

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
            command="find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune -o -type d -print 2> /dev/null | sed 1d | cut -b3- | @FZF_PATH@ +m"
        else:
            # match files and directories
            command="find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune -o -print 2> /dev/null | sed 1d | cut -b3- | @FZF_PATH@ +m"
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip())
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)
