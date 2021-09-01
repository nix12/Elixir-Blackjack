defmodule Blackjack.Accounts do
  require Logger

  import Ecto.Query, only: [from: 2]
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts.{Users, User}

  def authenticate_user(username, password) do
    query = from(u in User, where: u.username == ^username)

    case Repo.one(query) do
      nil ->
        no_user_verify()
        {:error, :invalid_credentials}

      user ->
        case check_pass(user, password) do
          {:error, reason} ->
            Logger.error("PASSWORD: #{inspect(password)}")
            Logger.error("USER PASS: #{inspect(user.password_hash)}")
            Logger.error("CHECK PASS ERROR: #{inspect(reason)}")
            {:error, reason}

          {:ok, _hashed_password} ->
            Logger.info("USER USER USER: #{inspect(user)}")
            {:ok, user}
        end
    end
  end

  def spawn_user(user) do
    Users.start_link(user)
  end

  def get_user(uuid) do
    Users.get_user(uuid)
  end
end
