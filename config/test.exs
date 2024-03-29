import Config

config :bcrypt_elixir, log_rounds: 4

config :libcluster,
  # debug: true,
  topologies: [
    blackjack: [
      strategy: Elixir.Cluster.Strategy.Gossip,
      config: [
        multicast_addr: "0.0.0.0",
        multicast_ttl: 2,
        secret: "somepassword"
      ]
    ]
  ]

config :blackjack, ecto_repos: [Blackjack.Repo]

config :blackjack, Blackjack.Repo,
  database: "blackjack_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  timeout: 60_000,
  pool: Ecto.Adapters.SQL.Sandbox

config :plug_cowboy, log_exceptions_with_status_code: [400..500]

config :blackjack, port: 4001

config :blackjack, Blackjack.AuthAccessPipeline,
  module: Blackjack.Accounts.Authentication.Guardian,
  error_handler: Blackjack.AuthErrorHandler

config :blackjack, Blackjack.Accounts.Authentication.Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "blackjack",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true
