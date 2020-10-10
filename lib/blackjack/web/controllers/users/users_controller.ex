defmodule Blackjack.Web.Controllers.UsersController do
  alias Blackjack.Repo
  alias Blackjack.Web.Models.User
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

  def show() do
    token = AuthenticationController.get_token()
    {:ok, %{"user" => %{"id" => id}}} = Guardian.decode_and_verify(token)

    {:ok, user} =
      Repo.get(User, id)
      |> Map.from_struct()
      |> Map.take([:id, :username])
      |> Jason.encode()

    user
  end
end
