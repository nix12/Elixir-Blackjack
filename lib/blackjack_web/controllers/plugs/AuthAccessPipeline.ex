defmodule Blackjack.AuthAccessPipeline do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :blackjack,
    module: Blackjack.Accounts.Authentication.Guardian,
    error_handler: Blackjack.AuthErrorHandler

  plug(Guardian.Plug.VerifyHeader, scheme: "Bearer")
  plug(Guardian.Plug.EnsureAuthenticated)
  plug(Guardian.Plug.LoadResource)
end
