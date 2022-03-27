import Config
import Dotenvy

source("./config/.env.#{config_env()}")

config :blackjack, Blackjack.Accounts.Authentication.Guardian,
  secret_key: env!("SECRET", :string!)
