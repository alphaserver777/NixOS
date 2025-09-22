{
  programs.git = {
    enable = true;
    userName = "crypto_mrx";
    userEmail = "maksim.ilonov@yandex.ru";
    extraConfig = {
      url."git@github.com:".insteadOf = "https://github.com/";
      fetch.prune = true;
    };
  };
}
