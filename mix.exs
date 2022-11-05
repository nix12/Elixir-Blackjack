defmodule Blackjack.MixProject do
  use Mix.Project

  def project do
    [
      app: :blackjack,
      version: "0.1.0",
      elixir: "~> 1.14.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        "test.watch": :test
      ],
      test_coverage: [
        ignore_modules: [
          Blackjack.Helpers,
          Blackjack.Factory,
          Blackjack.Repo,
          Blackjack.Accounts.Policy,
          Blackjack.NodeObserver,
          Blackjack.Accounts.Authentication.Guardian,
          Blackjack.Application,
          Blackjack.AuthAccessPipeline,
          Blackjack.AuthErrorHandler,
          Blackjack.RepoCase,
          Blackjack.Accounts.Authentication.Guardian.Plug,
          Jason.Encoder.Blackjack.Accounts.Friendship,
          Jason.Encoder.Blackjack.Accounts.User,
          Jason.Encoder.Blackjack.Core.Server,
          BlackjackWeb.Router,
          BlackjackWeb.AuthRouter,
          BlackjackWeb.StaticRouter
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Blackjack.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:ex_machina, "~> 2.7.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:faker, "~> 0.17", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.5.2"},
      {:httpoison, "~> 1.8"},
      {:guardian, "~> 2.3"},
      {:bodyguard, "~> 2.4.2"},
      {:jason, "~> 1.3"},
      {:bcrypt_elixir, "~> 2.3"},
      {:oban, "~> 2.8"},
      {:cachex, "~> 3.3"},
      {:distillery, "~> 2.1"},
      {:logger_file_backend, "~> 0.0"},
      {:dotenvy, "~> 0.3.0"},
      {:poolboy, "~> 1.5.2"},
      {:libcluster, git: "https://github.com/bitwalker/libcluster.git", ref: "a18a19c"},
      {:horde, "~> 0.8.5"}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
