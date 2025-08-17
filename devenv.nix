{ pkgs, ... }:

{
  packages = with pkgs; [
    elixir
    erlang
    nodejs
    postgresql
  ];

  languages.elixir.enable = true;

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_15;
    initialDatabases = [{ name = "email_tools_dev"; }];
    initialScript = "CREATE USER postgres SUPERUSER;";
  };

  scripts.setup.exec = ''
    mix deps.get
    mix ecto.setup
  '';

  processes.phoenix = {
    exec = "mix phx.server";
    process-compose = {
      depends_on = {
        postgres = {
          condition = "process_healthy";
        };
      };
    };
  };

  enterShell = ''
    echo "🧪 Elixir/Phoenix development environment loaded"
    echo "Run 'devenv run setup' for one-time project setup"
    echo "Run 'devenv up' to start services"
  '';
}