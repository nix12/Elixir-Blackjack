defmodule BlackjackWeb.Router do
  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  import Plug.Conn

  alias BlackjackWeb.Controllers.{
    RegistrationController,
    AuthenticationController,
    UsersController,
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

  # Registration routes
  post "/register" do
    case RegistrationController.create(conn) do
      {:ok, conn} ->
        conn
        |> resp(201, Jason.encode!(conn.assigns))

      {:errors, conn} ->
        conn
        |> resp(500, Jason.encode!(conn.assigns))
    end
    |> send_resp()
  end

  # Authentication routes
  post "/login" do
    case AuthenticationController.create(conn) do
      {:ok, conn} ->
        conn
        |> resp(200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        conn
        |> resp(422, Jason.encode!(conn.assigns))
    end
    |> send_resp()
  end

  delete "/logout" do
    {status, _body} = {200, AuthenticationController.delete(conn)}

    send_resp(conn, status, "User is logged out.")
  end

  # User routes

  put "/user" do
    {:ok, conn} = UsersController.update(conn)
    send_resp(conn, 200, Jason.encode!(conn.assigns))
  end

  # Server routes

  get "/servers" do
    conn = ServersController.index(conn)

    send_resp(conn, 200, Jason.encode!(conn.assigns))
  end

  get "/server/:server_name" do
    case ServersController.show(conn) do
      {:ok, conn} ->
        conn
        |> resp(200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        conn
        |> resp(422, Jason.encode!(conn.assigns))
    end
    |> send_resp()
  end

  post "/server/create" do
    case ServersController.create(conn) do
      {:ok, conn} ->
        conn
        |> resp(201, Jason.encode!(conn.assigns))

      {:errors, conn} ->
        conn
        |> resp(500, Jason.encode!(conn.assigns))
    end
    |> send_resp()
  end

  ## MAKE WEBSOCKET
  # post "/server/:server_name/join" do
  #   {status, _body} = {200, ServersController.join_server(conn)}

  #   send_resp(conn, status, "something")
  # end

  # post "/server/:server_name/leave" do
  #   {status, _body} = {200, ServersController.leave_server(conn)}

  #   send_resp(conn, status, "something")
  # end

  # Catch all routes and error handling.

  match _ do
    send_resp(conn, 404, "Route invalid.")
  end

  @impl true
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, %{errors: "Something went wrong!"} |> Jason.encode!())
  end
end
