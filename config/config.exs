import Config

import_config "#{config_env()}.exs"

config :bodyguard, default_error: :unauthorized
