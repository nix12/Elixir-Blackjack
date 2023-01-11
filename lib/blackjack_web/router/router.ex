defmodule BlackjackWeb.Router do
  @moduledoc """
    Direct incoming requests to either StaticRouter or
    AuthRouter.
  """
  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  alias BlackjackWeb.{StaticRouter, AuthRouter}

  plug(Plug.Logger)
  plug(:match)

  # plug(Plug.Parsers,
  #   parsers: [:json],
  #   pass: ["application/json"],
  #   json_decoder: Jason
  # )

  plug(:dispatch)

  match("/register", to: StaticRouter)
  match("/login", to: StaticRouter)

  match("/logout", to: AuthRouter)
  match("/servers", to: AuthRouter)
  match("/user/*_", to: AuthRouter)
  match("/server/*_", to: AuthRouter)
  match("/friendship/*_", to: AuthRouter)
end
