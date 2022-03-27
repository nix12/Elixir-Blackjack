defmodule BlackjackCli.Controllers.RegistrationController do
  import Plug.Conn

  alias Blackjack.Accounts.User

  def create(
        %{params: %{"user" => %{"username" => username, "password_hash" => password}}} = conn
      ) do
    case User.insert(%{
           username: username,
           password_hash: password,
           inserted_at: DateTime.utc_now(),
           updated_at: DateTime.utc_now()
         }) do
      {:ok, user} ->
        {:ok, assign(conn, :user, %{user | uuid: user.uuid |> Ecto.UUID.load!()})}

      {:errors, error} ->
        {:errors, assign(conn, :errors, error)}
    end
  end
end
