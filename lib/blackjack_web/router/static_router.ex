defmodule BlackjackWeb.StaticRouter do
  @moduledoc """
    This router contains routes where incoming traffic
    does not require authentication..
  """
  use Plug.Router
  if Mix.env() == :dev, do: use(Plug.Debugger)
  use Plug.ErrorHandler

  import Plug.Conn

  alias BlackjackWeb.Controllers.{
    RegistrationController,
    AuthenticationController
  }

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  post "/register" do
    case RegistrationController.create(conn) do
      {:ok, conn} ->
        conn
        |> resp(201, Jason.encode!(conn.assigns))

      {:errors, conn} ->
        conn
        |> resp(422, Jason.encode!(conn.assigns))
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

  # Catch all routes and error handling.

  match _ do
    send_resp(conn, 404, "Route invalid.")
  end

  @impl true
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, %{errors: "Something went wrong!"} |> Jason.encode!())
  end
end
