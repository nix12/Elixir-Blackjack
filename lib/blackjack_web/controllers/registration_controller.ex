defmodule BlackjackWeb.Controllers.RegistrationController do
  @moduledoc """
    Contains functions for user creation and registration.
  """
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  @doc """
    Creates a user or returns an error conn.
  """
  @spec create(Plug.Conn.t()) :: {:ok, Plug.Conn.t()} | {:errors, Plug.Conn.t()}
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
