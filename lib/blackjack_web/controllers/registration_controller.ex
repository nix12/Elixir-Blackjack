defmodule BlackjackWeb.Controllers.RegistrationController do
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  def create(
        %{
          params: %{
            "user" => %{"email" => email, "username" => username, "password_hash" => password}
          }
        } = conn
      ) do
    changeset =
      User.changeset(%User{}, %{email: email, username: username, password_hash: password})

    case changeset |> Repo.insert() do
      {:ok, user} ->
        {:ok, assign(conn, :user, user)}

      {:error, changeset} ->
        [{field, {message, _constraints}}] = changeset.errors

        {:errors, assign(conn, :errors, "#{field} #{message}.")}
    end
  end
end
