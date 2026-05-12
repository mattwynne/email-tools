{ pkgs, lib, config, ... }:
let
  fastmail-cli = pkgs.stdenv.mkDerivation {
    pname = "fastmail-cli";
    version = "2.2.2";
    src = pkgs.fetchurl {
      url = "https://github.com/radiosilence/fastmail-cli/releases/download/v2.2.2/fastmail-cli-darwin-aarch64.tar.gz";
      sha256 = "1awwh7cfd8r60ywn60gnx6ph98cq4sp7f3m57czmnbwjdpam9kgx";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin
      chmod +x $out/bin/fastmail-cli
    '';
  };
in
{
  packages = with pkgs; [
    nodejs
    gh
    lolcat
    fastmail-cli
  ];

  languages.typescript.enable = true;

  enterShell = ''
    echo
    echo "TypeScript development environment"
    echo "Run 'npm install' to install dependencies"
    echo "Run 'npm test' to run tests"
  '';
}
