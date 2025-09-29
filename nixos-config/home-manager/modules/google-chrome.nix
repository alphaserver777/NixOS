{ ... }:
{
  # Force Chrome to use Wayland/EGL to avoid GPU freezes on launch.
  home.file.".config/google-chrome-flags.conf".text = ''
    --ozone-platform=wayland
    --enable-features=UseOzonePlatform,WaylandWindowDecorations
    --use-gl=egl
    --disable-features=UseChromeOSDirectVideoDecoder
  '';
}
