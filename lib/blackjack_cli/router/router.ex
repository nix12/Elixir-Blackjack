defmodule BlackjackCLI.Router do
  require Logger

  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  alias Blackjack.Accounts
  alias Blackjack.Authentication

  alias BlackjackCLI.Controllers.{
    AuthenticationController,
    UsersController,
    ServersController
  }

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/ping" do
    send_resp(conn, 200, "PONG!")
  end

  # User routes
  post "/register" do
    {status, body} =
      case conn.body_params do
        %{"user" => user} ->
          {201, UsersController.create(conn, user)}

        error ->
          %{errors: [{name, err}]} = UsersController.create(conn, error)

          {422, "#{name} #{err |> elem(0)}\n"}
      end

    send_resp(conn, status, body)
  end

  # Authentication routes
  post "/login" do
    {status, token} =
      case conn.body_params do
        %{"user" => %{"username" => username, "password_hash" => password}} ->
          case Authentication.authenticate_user(username, password) do
            {:ok, _user} ->
              Accounts.spawn_user(username)
              {200, AuthenticationController.login(conn)}

            {:error, _user} ->
              {422, "ERROR"}
          end

        _ ->
          {422, "ERROR"}
      end

    send_resp(conn, status, token)
  end

  delete "/logout" do
    {status, _body} = {200, AuthenticationController.logout(conn)}
    send_resp(conn, status, "User is logged out.")
  end

  # Server routes

  get "/servers" do
    {status, body} = {200, ServersController.get_servers(conn)}

    send_resp(conn, status, body)
  end

  get "/server/:server_name" do
    {status, body} = {200, ServersController.get_server(conn)}

    send_resp(conn, status, body)
  end

  # Catch all routes and error handling.

  match _ do
    send_resp(conn, 404, "Route invalid.")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong!")
  end
end
