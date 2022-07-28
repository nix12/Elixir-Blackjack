import(Config)

config :libcluster,
  # debug: true,
  topologies: [
    blackjack: [
      strategy: Elixir.Cluster.Strategy.Gossip,
      config: [
        # port: 45892,
        # if_addr: "0.0.0.0",
        # multicast_if: "192.168.1.1",
        multicast_addr: "0.0.0.0",
        multicast_ttl: 2,
        secret: "somepassword"
      ]
    ]
  ]

config :logger, backends: [{LoggerFileBackend, :info_log}]

config :logger, :info_log,
  path: './lib/blackjack/logs/blackjack_logs.log' |> Path.expand(),
  level: :info

config :blackjack, ecto_repos: [Blackjack.Repo]

config :blackjack, Blackjack.Repo,
  database: "blackjack_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  timeout: 60_000,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

config :plug_cowboy, log_exceptions_with_status_code: [400..500]

config :blackjack, Blackjack.AuthAccessPipeline,
  module: Blackjack.Guardian,
  error_handler: Blackjack.AuthErrorHandler

config :blackjack, Blackjack.Accounts.Authentication.Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "blackjack",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true

port =
  IO.gets("What port would you like to play Blackjack on? (default port is 4000)\n")
  |> String.trim()

config :blackjack,
  port: if(port == "", do: 4000, else: port |> String.to_integer())
