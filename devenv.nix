{ pkgs, lib, config, ... }:
{
  packages = with pkgs; [
    elixir
    erlang
    nodejs
    postgresql
    flyctl
    gh
    lolcat
  ];

  languages.elixir.enable = true;

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_15;
    initialDatabases = [{ name = "inbox_coach_dev"; }];
    initialScript = "CREATE USER postgres SUPERUSER;";
  };

  scripts.setup.exec = ''
    cd inbox_coach
    mix deps.get
    mix ecto.setup
  '';

  processes = {} //
    lib.optionalAttrs (!config.devenv.isTesting) {
      phoenix = {
        exec = ''
          cd inbox_coach
          mix phx.server
        '';
        process-compose = {
          depends_on = {
            postgres = {
              condition = "process_healthy";
            };
          };
        };
      };
    };

  enterShell = ''
    cat logo | lolcat -p .5
    echo
    echo "Run 'devenv up -d' to start services"
    echo "Run 'setup' for one-time project setup"
  '';

  enterTest = ''
    echo "Running setup..."
    cd inbox_coach
    mix deps.get
    mix ecto.setup
    echo "Setup complete"
    echo "Running mix test..."
    mix test.all
  '';
}
