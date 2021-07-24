defmodule BlackjackCLI.Controllers.UsersController do
  alias Blackjack.Repo
  # Change to accounts api file
  alias Blackjack.Accounts.User
  alias Blackjack.Authentication.Guardian
  alias BlackjackCLI.Controllers.{AuthenticationController, RegistrationsController}

  def create(_conn, user) do
    changeset = User.changeset(%User{}, user)

    case Repo.insert(changeset) do
      {:ok, registered} ->
        registered.username

      {:error, changeset} ->
        IO.inspect(changeset, label: "ERROR")
        changeset
    end
  end
end
