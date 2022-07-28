defmodule Blackjack.AuthAccessPipeline do
  use Guardian.Plug.Pipeline, otp_app: :blackjack

  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource)
end
