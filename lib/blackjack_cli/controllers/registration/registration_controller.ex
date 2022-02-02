defmodule BlackjackCli.Controllers.RegistrationController do
  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  def create(conn) do
    changeset = User.changeset(%User{}, conn.body_params["user"])

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, user}

      {:error, %{errors: [{field, {error, _}}]}} ->
        {:error, "#{field} #{error}."}
    end
  end
end
