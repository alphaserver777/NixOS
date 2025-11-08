{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.blacklistedKernelModules = [ "kvm-intel" "kvm-amd" ];
}
