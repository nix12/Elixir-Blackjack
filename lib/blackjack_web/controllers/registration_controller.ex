defmodule BlackjackWeb.Controllers.RegistrationController do
  @moduledoc """
    Contains functions for user creation and registration.
  """
  import Plug.Conn

  alias Ecto.Multi
  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  @doc """
    Creates a user or returns an error conn.
  """
  @spec create(Plug.Conn.t()) :: {:ok, Plug.Conn.t()} | {:errors, Plug.Conn.t()}
  def create(%{params: params} = conn) do
    case create_account(params) do
      {:ok, user} ->
        {:ok, assign(conn, :user, user)}

      {:error, changeset} ->
        [{field, {message, _constraints}}] = changeset.errors

        {:errors, assign(conn, :errors, "#{field} #{message}.")}
    end
  end

  def create_account(%{
        "user" => %{"email" => email, "username" => username, "password_hash" => password}
      }) do
    Multi.new()
    |> Multi.insert(
      :create_user,
      User.changeset(%User{}, %{
        email: email,
        username: username,
        password_hash: password
      })
    )
    |> Multi.insert(:create_inbox, fn %{create_user: user} ->
      Ecto.build_assoc(user, :inbox)
    end)
    |> Repo.transaction()
  end
end
