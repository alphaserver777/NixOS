from ranger.api.commands import Command

class search_content(Command):
    """
    :search_content <query>

    Searches for a string in all files in the current directory and shows the results in fzf.
    """
    def execute(self):
        if self.arg(1):
            query = self.rest(1)
            command = "tmux display-popup -E \"rg --line-number --no-heading --color=always '%s' | fzf\"" % query
            self.fm.execute_command(command, universal_newlines=True)
        else:
            self.fm.notify("Usage: search_content <query>", bad=True)

    def tab(self, tabnum):
        return self._tab_directory_content()
