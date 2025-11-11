defmodule InboxCoach.MixProject do
  use Mix.Project

  def project do
    [
      app: :inbox_coach,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_paths: ["lib"]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {InboxCoach.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [preferred_envs: ["test.all": :test]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:bandit, "~> 1.5"},
      {:cloak, "~> 1.1"},
      {:cloak_ecto, "~> 1.3"},
      {:dns_cluster, "~> 0.1.1"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:faker, "~> 0.18", only: :test},
      {:finch, "~> 0.17"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.20"},
      {:ex_heroicons, "~> 3.1.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.2"},
      {:mix_test_interactive, "~> 3.2", runtime: false},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.1", override: true},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_test, "~> 0.7.1", only: :test, runtime: false},
      {:postgrex, ">= 0.0.0"},
      {:req, "~> 0.5.5"},
      {:swoosh, "~> 1.5"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tesla, "~> 1.12.1"},
      {:tzdata, "~> 1.1"},
      {:uniq, "~> 0.1"},
      {:webdavex, "~> 0.3.3"},
      {:ex_unit_notifier, "~> 1.3", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --exclude online"],
      "test.all": ["ecto.create --quiet", "ecto.migrate --quiet", "test --include online"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind inbox_coach", "esbuild inbox_coach"],
      "assets.deploy": [
        "tailwind inbox_coach --minify",
        "esbuild inbox_coach --minify",
        "phx.digest"
      ]
    ]
  end
end
