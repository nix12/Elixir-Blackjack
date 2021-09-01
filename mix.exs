defmodule Blackjack.MixProject do
  use Mix.Project

  def project do
    [
      app: :blackjack,
      version: "0.1.0",
      elixir: "~> 1.12.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Blackjack.Application, []},
      applications: [:guardian, :bodyguard, :cachex],
      extra_applications: [
        :logger,
        :postgrex,
        :ecto,
        :plug_cowboy,
        :pubsub,
        :ratatouille,
        :inets,
        :jason,
        :bcrypt_elixir,
        :ecto_sql
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:pubsub, "~> 1.0"},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.0"},
      {:guardian, "~> 2.0"},
      {:bodyguard, "~> 2.4"},
      {:jason, "~> 1.2"},
      {:bcrypt_elixir, "~> 2.3"},
      {:ratatouille, "~> 0.5.1"},
      {:gen_stage, "~> 1.0"},
      {:broadway, "~> 0.6.0"},
      {:oban, "~> 2.8"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:cachex, "~> 3.3"},
      {:distillery, "~> 2.1"},
      {:logger_file_backend, "~> 0.0"},
      {:dotenvy, "~> 0.3.0"}
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
