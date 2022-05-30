defmodule BlackjackWeb.Controllers.RegistrationController do
  require Logger

  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  @spec create(Plug.Conn.t()) :: {:errors, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def create(
        %{params: %{"user" => %{"username" => username, "password_hash" => password}}} = conn
      ) do
    changeset = User.changeset(%User{}, %{username: username, password_hash: password})

    case changeset |> Repo.insert() do
      {:ok, user} ->
        {:ok, assign(conn, :user, user)}

      {:error, changeset} ->
        [{field, {message, _constraints}}] = changeset.errors

        {:errors, assign(conn, :errors, "#{field} #{message}.")}
    end
  end
end
