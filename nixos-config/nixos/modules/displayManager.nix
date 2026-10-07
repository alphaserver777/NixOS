{ pkgs, ... }:
let
  loginTheme = (pkgs.sddm-astronaut.override {
    themeConfig = {
      Background = "Backgrounds/space.png";
      Font = "Noto Sans";
      Locale = "ru_RU";
      HourFormat = "HH:mm";
      DateFormat = "dddd, d MMMM";
      HeaderText = "Добро пожаловать";
      RoundCorners = "20";
      FormPosition = "center";
      PartialBlur = "true";
      FullBlur = "false";
      DimBackground = "0.2";
      BackgroundColor = "#1e1e2e";
      FormBackgroundColor = "#1e1e2e";
      DimBackgroundColor = "#1e1e2e";
      HeaderTextColor = "#cdd6f4";
      TimeTextColor = "#cdd6f4";
      DateTextColor = "#b4befe";
      LoginFieldBackgroundColor = "#313244";
      PasswordFieldBackgroundColor = "#313244";
      LoginFieldTextColor = "#cdd6f4";
      PasswordFieldTextColor = "#cdd6f4";
      PlaceholderTextColor = "#a6adc8";
      LoginButtonBackgroundColor = "#89b4fa";
      LoginButtonTextColor = "#1e1e2e";
      HighlightBorderColor = "#cba6f7";
      HighlightBackgroundColor = "#45475a";
      WarningColor = "#f38ba8";
      HideVirtualKeyboard = "true";
      PasswordFocus = "true";
      TranslatePlaceholderUsername = "Имя пользователя";
      TranslatePlaceholderPassword = "Пароль";
      TranslateLogin = "Войти";
      TranslateLoginFailedWarning = "Не удалось войти: проверьте имя и пароль";
      TranslateCapslockWarning = "Включён верхний регистр";
      TranslateSuspend = "Сон";
      TranslateHibernate = "Сохранить сеанс и выключить";
      TranslateReboot = "Перезагрузить";
      TranslateShutdown = "Выключить";
      TranslateSessionSelection = "Выбор сеанса";
    };
  }).overrideAttrs (old: {
    # Пакет темы не вызывает postInstall, поэтому дополняем сам этап установки.
    installPhase = old.installPhase + ''
      chmod u+w "$out/share/sddm/themes/sddm-astronaut-theme/Backgrounds"
      cp ${../../wallpapers/space.png} "$out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/space.png"
    '';
  });
in
{
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    # Тема использует Qt 6: программа входа и её библиотеки должны совпадать.
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs.kdePackages; [ qtsvg qtmultimedia qtvirtualkeyboard ];
  };
  environment.systemPackages = [ loginTheme ];
  fonts.packages = [ pkgs.noto-fonts ];
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.sessionPackages = [ pkgs.hyprland ];
}
