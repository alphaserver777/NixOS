{ ... }:
{
  # Задача 034: пробное сглаживание для горизонтальных LCD-экранов main.
  # При цветной кайме вернуть rgba = "none" и проверить порядок субпикселей.
  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      autohint = false;
      style = "slight";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };
}
