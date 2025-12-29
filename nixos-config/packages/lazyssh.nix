{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "lazyssh-client";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "Adembc";
    repo = "lazyssh";
    rev = "v${version}";
    sha256 = "sha256-6halWoLu9Vp6XU57wAQXaWBwKzqpnyoxJORzCbyeU5Q=";
  };

  vendorHash = "sha256-OMlpqe7FJDqgppxt4t8lJ1KnXICOh6MXVXoKkYJ74Ks=";

  postInstall = ''
    mv $out/bin/cmd $out/bin/lazyssh
  '';

  meta = with lib; {
    description = "LazySSH - simple SSH shortcut manager";
    homepage = "https://github.com/Adembc/lazyssh";
    license = licenses.asl20;
  };
}
