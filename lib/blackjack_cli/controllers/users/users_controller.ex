defmodule BlackjackCLI.Controllers.UsersController do
  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  def create(_conn, user) do
    changeset = User.changeset(%User{}, user)

    case Repo.insert(changeset) do
      {:ok, registered} ->
        registered.username

      {:error, changeset} ->
        changeset
    end
  end
end
