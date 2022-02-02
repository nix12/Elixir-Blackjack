defmodule BlackjackCli.Router do
  require Logger

  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  import Plug.Conn

  alias BlackjackCli.Controllers.{
    RegistrationController,
    AuthenticationController,
    ServersController
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
      case RegistrationController.create(conn) do
        {:ok, user} ->
          {201, assign(conn, :user, user)}

        {:error, error_message} ->
          {500, assign(conn, :error, error_message)}
      end

    send_resp(conn, status, Jason.encode!(conn_or_errors.assigns))
  end

  # Authentication routes
  post "/login" do
    IO.inspect(conn, label: "ROUTER START")

    case AuthenticationController.create(conn) do
      {:ok, conn} ->
        conn
        |> resp(200, Jason.encode!(conn.assigns))
        |> IO.inspect(label: "RESPONSE")
        |> send_resp()

      {:error, conn} ->
        conn
        |> resp(422, Jason.encode!(conn.assigns))
        |> IO.inspect(label: "RESPONSE")
        |> send_resp()
    end
  end

  delete "/logout" do
    {status, _body} = {200, AuthenticationController.delete(conn)}

    send_resp(conn, status, "User is logged out.")
  end

  # Server routes

  get "/servers" do
    {status, body} = {200, ServersController.index(conn)}

    send_resp(conn, status, Jason.encode!(body))
  end

  get "/server/:server_name" do
    {status, body} = {200, ServersController.show(conn)}

    send_resp(conn, status, Jason.encode!(body))
  end

  post "/server/create" do
    {status, body} = {201, ServersController.create(conn)}

    send_resp(conn, status, Jason.encode!(body))
  end

  post "/server/:server_name/join" do
    {status, _body} = {200, AccountsController.join_server(conn)}

    send_resp(conn, status, "something")
  end

  post "/server/:server_name/leave" do
    {status, _body} = {200, AccountsController.leave_server(conn)}

    send_resp(conn, status, "something")
  end

  # Catch all routes and error handling.

  match _ do
    send_resp(conn, 404, "Route invalid.")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, %{errors: "Something went wrong!"})
  end
end
