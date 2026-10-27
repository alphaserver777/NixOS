{ lib, ... }:
{
  # Задача 035: общая основа без предположений о строении матрицы.
  # Серое сглаживание подходит разному порядку субпикселей и повороту экрана.
  # Полная привязка контуров к сетке повышает резкость, но меняет форму букв.
  fonts.fontconfig = {
    antialias = lib.mkDefault true;
    hinting = {
      enable = lib.mkDefault true;
      autohint = lib.mkDefault false;
      style = lib.mkDefault "full";
    };
    subpixel.rgba = lib.mkDefault "none";
  };
}
