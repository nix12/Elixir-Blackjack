defmodule Blackjack.MixProject do
  use Mix.Project

  def project do
    [
      app: :blackjack,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:guardian, :authorize],
      extra_applications: [:logger, :plug_cowboy, :ecto, :postgrex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
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
      {:bcrypt_elixir, "~> 2.0"}
    ]
  end

  def escript do
    [main_module: Blackjack.Commandline.CLI]
  end
end
