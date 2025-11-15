{ pkgs, lib, config, inputs, ... }:
{
  packages = with pkgs; [
    elixir
    erlang
    nodejs
    postgresql
    flyctl
    gh
    lolcat
    svgbob
    just
    inputs.beads.packages.${pkgs.system}.default
  ];

  languages.elixir.enable = true;
  languages.elixir.package = pkgs.beam27Packages.elixir_1_17;

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_15;
    initialScript = ''
      CREATE USER postgres WITH SUPERUSER PASSWORD 'postgres';
    '';
    initialDatabases = [
      { name = "inbox_coach_dev"; }
      { name = "inbox_coach_test"; }
    ];
    listen_addresses = "*";
  };

  scripts.setup.exec = ''
    mix deps.get
    mix ecto.setup
  '';

  processes = {} //
    lib.optionalAttrs (!config.devenv.isTesting) {
      phoenix = {
        exec = ''
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
    echo "Waiting for postres to start"
    wait_for_port 5432 30

    echo "Postgres started. Getting deps and running tests..."
    mix deps.get
    mix test.all
  '';
}
