import(Config)

# port =
#   IO.gets("What port would you like to play Blackjack on? (default port is 4000)\n")
#   |> String.trim()

# config :blackjack,
#   port: if(port == "", do: 4000, else: port |> String.to_integer())

config :blackjack, port: 4000

Node.start(:"blackjack_server_#{:rand.uniform(999_999)}", :shortnames)

config :libcluster,
  debug: true,
  topologies: [
    blackjack: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        multicast_addr: "0.0.0.0"
      ]
    ]
  ]

config :logger, backends: [{LoggerFileBackend, :info_log}]

config :logger, :info_log,
  path: './lib/blackjack/logs/blackjack_logs.log' |> Path.expand(),
  level: :info,
  format: "[$level] #{node()} $metadata: $message\n",
  metadata: [:registered_name]

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
  verify_module: Guardian.Token.Jwt.Verify,
  issuer: "blackjack",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true
