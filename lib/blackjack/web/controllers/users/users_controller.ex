defmodule Blackjack.Web.Controllers.UsersController do
  alias Blackjack.Repo
  # Change to accounts api file
  alias Blackjack.Accounts.User
  alias Blackjack.Web.Controllers.AuthenticationController
  alias Blackjack.Authentication.Guardian

  def create(_conn, user) do
    changeset = User.changeset(%User{}, user)

    case Repo.insert(changeset) do
      {:ok, registered} ->
        registered.username

      {:error, changeset} ->
        changeset
    end
  end

  def get() do
    token = AuthenticationController.get_token()
    {:ok, %{"user" => %{"username" => username}}} = Guardian.decode_and_verify(token)

    case Repo.get_by!(User, username: username) do
      user ->
        user
        |> Map.from_struct()
        |> Map.take([:id, :username])
        |> Jason.encode()

      {:error, changeset} ->
        changeset
    end
  end
end
