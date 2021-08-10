defmodule BlackjackCLI.Controllers.AuthenticationController do
  alias Blackjack.Authentication.Guardian

  def login(conn) do
    conn
    |> Guardian.Plug.sign_in(conn.body_params)
    |> Guardian.Plug.current_token()
  end

  def logout(conn) do
    Guardian.Plug.sign_out(conn)
  end

  def send_credentials(conn) do
    {:ok, {response, _, body}} =
      :httpc.request(
        :post,
        {"http://localhost:4000/login", [], 'application/json', Jason.encode!(conn.assigns)},
        [],
        []
      )

    case response do
      {_http, status, message} when status >= 500 ->
        {:error, message}

      {_http, status, _message} when status >= 400 and status < 500 ->
        {:error, "Failed to create new user account.\n"}

      {_http, status, _message} when status >= 200 and status < 400 ->
        {:ok, response, body}
    end
  end
end
