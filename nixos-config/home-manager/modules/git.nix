{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "crypto_mrx";
        email = "maksim.ilonov@yandex.ru";
      };
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
      url."git@gitflic.ru:".insteadOf = "https://gitflic.ru/";
      fetch.prune = true;
      init.defaultBranch = "main";
    };
  };
}
