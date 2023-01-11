defmodule BlackjackWeb.AuthRouter do
  @moduledoc """
    This router contains routes where incoming traffic must
    be authenticated.
  """
  require Logger

  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  import Plug.Conn

  alias BlackjackWeb.Controllers.{
    UsersController,
    FriendshipsController,
    ServersController,
    AuthenticationController
  }

  plug(:match)
  plug(Blackjack.AuthAccessPipeline)
  plug(:log)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason,
    validate_utf8: true
  )

  plug(:log)
  plug(:dispatch)

  # User routes

  delete "/logout" do
    case AuthenticationController.destroy(conn) do
      {:ok, conn} ->
        send_resp(conn, 200, "User is logged out.")

      {:error, conn} ->
        send_resp(conn, 500, "Failed to logout.")
    end
  end

  put "/user/:id/update" do
    case UsersController.update(conn) do
      {:ok, conn} ->
        send_resp(conn, 200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        send_resp(conn, 422, Jason.encode!(conn.assigns))
    end
  end

  get "/user/:id" do
    case UsersController.show(conn) do
      {:ok, conn} ->
        send_resp(conn, 200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        send_resp(conn, 401, Jason.encode!(conn.assigns))
    end
  end

  # Friendship routes

  post "/friendship/create" do
    case FriendshipsController.create(conn) do
      {:ok, conn} ->
        send_resp(conn, 201, Jason.encode!(conn.assigns))

      {:error, conn} ->
        send_resp(conn, 401, Jason.encode!(conn.assigns))
    end
  end

  post "/friendship/:friend_id/accept" do
    case FriendshipsController.accept(conn) do
      {:ok, conn} ->
        send_resp(conn, 200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        send_resp(conn, 401, Jason.encode!(conn.assigns))
    end
  end

  post "/friendship/:friend_id/decline" do
    case FriendshipsController.decline(conn) do
      {:ok, conn} ->
        send_resp(conn, 200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        send_resp(conn, 401, Jason.encode!(conn.assigns))
    end
  end

  delete "/friendship/:friend_id/destroy" do
    case FriendshipsController.destroy(conn) do
      {:ok, conn} ->
        send_resp(conn, 200, Jason.encode!(conn.assigns))

      {:error, conn} ->
        send_resp(conn, 401, Jason.encode!(conn.assigns))
    end
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
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(conn.assigns))

      {:errors, conn} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(conn.assigns))
    end
  end

  # Catch all routes and error handling.

  match _ do
    send_resp(conn, 404, "Route invalid.")
  end

  @impl true
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, %{errors: "Something went wrong!"} |> Jason.encode!())
  end

  def log(conn, _opts) do
    Logger.info(conn.params |> inspect())

    conn
  end
end
