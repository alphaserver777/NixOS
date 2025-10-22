{
  programs.git = {
    enable = true;
    userName = "crypto_mrx";
    userEmail = "maksim.ilonov@yandex.ru";
    extraConfig = {
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitflic.ru:".insteadOf = "https://gitflic.ru/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
      fetch.prune = true;
    };
  };
}
