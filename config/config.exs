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
  secret_key: System.fetch_env!("SECRET")

port =
  IO.gets("What port would you like to play Blackjack on? (default port is 4000)\n")
  |> String.trim()

config :blackjack,
  port: if(length(String.to_charlist(port)) == 0, do: 4000, else: port |> String.to_integer())
