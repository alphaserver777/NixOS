{ pkgs, ... }:

{
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    # Ключами SSH управляет отдельная служба из sshAgent.nix.
    enableSshSupport = false;
    pinentry.package = pkgs.pinentry-gnome3;
  };
}
