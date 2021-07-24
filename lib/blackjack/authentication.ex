defmodule Blackjack.Authentication do
  import Ecto.Query, only: [from: 2]
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  def authenticate_user(username, password) do
    query = from(u in User, where: u.username == ^username)

    case Repo.one(query) do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
end
