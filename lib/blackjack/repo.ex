defmodule Blackjack.Repo do
  use Ecto.Repo,
    otp_app: :blackjack,
    adapter: Ecto.Adapters.Postgres
end
