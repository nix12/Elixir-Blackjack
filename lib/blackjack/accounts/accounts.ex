defmodule Blackjack.Accounts do
  require Logger

  import Ecto.Query
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Core
  alias Blackjack.Accounts.{Users, User, Supervisor}

  def register_user(conn) do
    changeset = User.changeset(%User{}, conn.body_params["user"])

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, user}

      {:error, %{errors: [{field, {error, _}}]}} ->
        {:error, "#{field} #{error}."}
    end
  end

  def authenticate_user(username, password) do
    query =
      from(u in "users",
        where: u.username == ^username,
        select: [:username, :password_hash]
      )

    case Repo.one(query) do
      nil ->
        no_user_verify()
        {:error, :invalid_credentials}

      user ->
        case check_pass(user, password) do
          {:error, reason} ->
            {:error, reason}

          {:ok, _hashed_password} ->
            {:ok, user}
        end
    end
  end

  def spawn_user(user) do
    Supervisor.register(user)
  end

  def get_user(username) do
    Users.get_user(username)
  end

  def join_server(username, server_name) do
    # Users.join_server(username, server_name)
    # Node.spawn_link(Node.self(), fn ->
    Core.add_user_to_server(server_name, username)
    # end)
  end

  def leave_server(username, server_name) do
    # Users.leave_server(username, server_name)
    # Node.spawn_link(Node.self(), fn ->
    Core.remove_user_from_server(server_name, username)
    # end)
  end
end
