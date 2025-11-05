{ pkgs, lib, config, ... }:
{
  packages = with pkgs; [
    nodejs
    gh
    lolcat
  ];

  languages.typescript.enable = true;

  enterShell = ''
    cat logo | lolcat -p .5
    echo
    echo "TypeScript development environment"
    echo "Run 'npm install' to install dependencies"
    echo "Run 'npm test' to run tests"
  '';
}
