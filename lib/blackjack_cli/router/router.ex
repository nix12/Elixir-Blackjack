defmodule BlackjackCLI.Router do
  require Logger

  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  import Plug.Conn

  alias BlackjackCLI.Controllers.{
    AccountsController,
    CoreController
  }

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # User routes
  post "/register" do
    {status, conn_or_errors} =
      case AccountsController.register_user(conn) do
        {:ok, user} ->
          {201, assign(conn, :user, user)}

        {:errors, error_message} ->
          Logger.info(inspect(error_message))
          {500, assign(conn, :errors, error_message)}
      end

    send_resp(conn, status, Jason.encode!(conn_or_errors.assigns))
  end

  # Authentication routes
  post "/login" do
    {status, conn_or_reason} =
      case AccountsController.login(conn) do
        {:ok, conn} ->
          Logger.info("USER: #{inspect(conn.assigns.user)}")
          {200, conn}

        {:error, reason} ->
          {422, assign(conn, :errors, reason)}

        _ ->
          {500, "Internal Server Error"}
      end

    Logger.info("CONN OR REASON: #{inspect(conn_or_reason.assigns)}")
    send_resp(conn, status, Jason.encode!(conn_or_reason.assigns))
  end

  delete "/logout" do
    {status, _body} = {200, AccountsController.logout(conn)}
    send_resp(conn, status, "User is logged out.")
  end

  # Server routes

  get "/servers" do
    {status, body} = {200, CoreController.get_servers(conn)}

    send_resp(conn, status, body)
  end

  get "/server/:server_name" do
    {status, body} = {200, CoreController.get_server(conn)}

    send_resp(conn, status, body)
  end

  get "/server/create" do
    {status, body} = {200, CoreController.create_server(conn)}

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
