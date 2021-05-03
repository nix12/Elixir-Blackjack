defmodule Blackjack.MixProject do
  use Mix.Project

  def project do
    [
      app: :blackjack,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Blackjack.Application, []},
      applications: [:guardian, :authorize],
      extra_applications: [:logger, :plug_cowboy, :ecto, :postgrex, :pubsub]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:pubsub, "~> 1.0"},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.0"},
      {:guardian, "~> 2.0"},
      {:authorize, "~> 1.0.0"},
      {:jason, "~> 1.2"},
      {:bcrypt_elixir, "~> 2.3"},
      {:ratatouille, "~> 0.5.1"},
      {:gen_stage, "~> 1.0"},
      {:flow, "~> 1.0"},
      {:hashids, "~> 2.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:cachex, "~> 3.3"}
    ]
  end
end
