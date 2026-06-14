{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../packages/assistant.nix { })
  ];

  # Ассистент использует legacy XLoadFont() для шрифтов в окне удалённого
  # рабочего стола — это блокирующий запрос к X-серверу (XWayland), а не
  # к клиенту. Без core X11 bitmap-шрифтов в системном fontconfig XWayland
  # не находит их и зависает, что фризит весь UI Ассистента.
  fonts.packages = with pkgs; [
    xorg.fontmiscmisc
    xorg.fontcursormisc
    xorg.fontadobe75dpi
    xorg.fontadobe100dpi
    xorg.fontbh75dpi
    xorg.fontbh100dpi
    xorg.fontbhlucidatypewriter75dpi
    xorg.fontbhlucidatypewriter100dpi
    xorg.fontbhttf
    xorg.fontbitstream75dpi
    xorg.fontbitstream100dpi
    dejavu_fonts
    liberation_ttf
  ];
}
