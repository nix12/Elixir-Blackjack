defmodule BlackjackCLI.Controllers.RegistrationsController do
  def send_credentials(conn) do
    {:ok, {response, _, body}} =
      :httpc.request(
        :post,
        {'http://localhost:4000/register', [], 'application/json', Jason.encode!(conn.assigns)},
        [],
        []
      )

    case response do
      {_http, status, message} when status >= 500 ->
        {:error, message}

      {_http, status, _message} when status >= 400 and status < 500 ->
        {:error, "Wrong username or password.\n"}

      {_http, status, _message} when status >= 200 and status < 400 ->
        {:ok, response, body}
    end
  end
end
