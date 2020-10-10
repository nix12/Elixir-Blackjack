import Config

config :blackjack, ecto_repos: [Blackjack.Repo]

config :blackjack, Blackjack.Repo,
  database: "blackjack_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :blackjack, Blackjack.Authentication.Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "blackjack",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true,
  secret_key: System.get_env("SECRET")

config :bcrypt_elixir, :log_rounds, 5
