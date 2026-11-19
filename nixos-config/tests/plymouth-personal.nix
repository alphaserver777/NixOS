{ pkgs }:
pkgs.testers.runNixOSTest {
  name = "plymouth-personal";
  globalTimeout = 180;
  extraPythonPackages = p: [ p.pillow ];
  nodes.machine = { ... }: {
    boot.initrd.systemd.enable = true;
    boot.initrd.kernelModules = [ "virtio_gpu" ];
    boot.kernelParams = [ "quiet" "plymouth.ignore-serial-consoles" ];
    boot.plymouth = {
      enable = true;
      theme = "black_hud";
      themePackages = [ (pkgs.callPackage ../packages/plymouth-personal.nix { }) ];
    };
    # Только в испытательной машине: оставляем заставку для снимков.
    systemd.services.plymouth-quit.enable = false;
    systemd.services.plymouth-quit-wait.enable = false;
    systemd.services."getty@tty1".enable = false;
    virtualisation = {
      memorySize = 1024;
      cores = 1;
      resolution = { x = 1280; y = 800; };
      qemu.options = [ "-vga none" "-device virtio-vga" ];
    };
  };
  testScript = ''
    import os
    import time
    from PIL import Image, ImageChops

    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("plymouth --ping")
    # Два полных цикла: сохраняем реальные снимки видеовыхода машины.
    samples = []
    for index in range(16):
        path = os.path.join(machine.out_dir, f"signature-{index:02d}.png")
        machine.screenshot(path)
        samples.append(Image.open(path).convert("RGB"))
        time.sleep(0.8)
    width, height = samples[0].size
    # Подпись ниже кольца; чёрный фон позволяет измерить её яркость.
    band = (int(width * 0.08), int(height / 2 + 210),
            int(width * 0.92), min(height, int(height / 2 + 290)))
    brightness = [sum(frame.crop(band).convert("L").getdata()) for frame in samples]
    assert max(brightness) > 10000, "Подпись не появилась"
    assert min(brightness) < max(brightness) * 0.15, "Подпись не исчезает"
    assert len(set(brightness)) > 5, "Нет плавного изменения прозрачности"
    assert any(ImageChops.difference(samples[0], frame).getbbox() for frame in samples[1:]), "Анимация не движется"
    machine.succeed("plymouth quit")
    machine.fail("plymouth --ping")
  '';
}
