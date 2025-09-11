{ pkgs, lib, config, ... }:
{
  packages = with pkgs; [
    elixir
    erlang
    nodejs
    postgresql
    flyctl
    gh
  ];

  languages.elixir.enable = true;

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_15;
    initialDatabases = [{ name = "email_tools_dev"; }];
    initialScript = "CREATE USER postgres SUPERUSER;";
  };

  scripts.setup.exec = ''
    cd email_tools
    mix deps.get
    mix ecto.setup
  '';

  processes = {} //
    lib.optionalAttrs (!config.devenv.isTesting) {
      phoenix = {
        exec = ''
          cd email_tools
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
    echo "🧪 Elixir/Phoenix development environment loaded"
    echo "Run 'devenv run setup' for one-time project setup"
    echo "Run 'devenv up' to start services"
  '';

  enterTest = ''
    wait_for_port 5432
    devenv run setup
    cd email_tools
    mix test
  '';
}
