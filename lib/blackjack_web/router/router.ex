defmodule BlackjackWeb.Router do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  use Plug.ErrorHandler

  alias BlackjackWeb.Controllers.{
    AuthenticationController,
    UsersController
  }

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # User routes
  post "/user/register" do
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

  get "/user/:id/info" do
    {status, body} = {200, UsersController.get()}

    send_resp(conn, status, body)
  end

  get "/user/:username" do
    {status, body} = {200, UsersController.get()}

    send_resp(conn, status, body)
  end

  # Authentication routes
  post "/login" do
    {status, token} =
      case conn.body_params do
        %{"user" => user} ->
          {200, AuthenticationController.login(conn, user)}

        _ ->
          {422, "Wrong Username or Password.\n"}
      end

    AuthenticationController.store_token(token)

    send_resp(conn, status, "")
  end

  delete "/logout" do
    {status, _body} = {200, AuthenticationController.logout(conn)}
    send_resp(conn, status, "User is logged out.")
  end

  match _ do
    send_resp(conn, 404, "Route invalid.")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
