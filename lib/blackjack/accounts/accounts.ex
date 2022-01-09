defmodule Blackjack.Accounts do
  require Logger

  import Ecto.Query
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Core
  alias Blackjack.Accounts.{Users, User, Supervisor}

  # defmacrop uuid_eq(user_uuid) do
  #   quote bind_quoted: [user_uuid: user_uuid] do
  #     {:ok, binary_user_uuid} =
  #       user_uuid |> Ecto.UUID.dump() |> tap(&Logger.info("DUMP: #{inspect(&1)}"))

  #     {:ok, string_user_uuid} =
  #       binary_user_uuid |> Ecto.UUID.load() |> tap(&Logger.info("LOAD: #{inspect(&1)}"))

  #     unquote(string_user_uuid)
  #   end
  # end

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
        where: [username: ^username],
        select: %{
          username: u.username,
          password_hash: u.password_hash,
          uuid: type(u.uuid, :string)
        }
      )

    # Logger.info("QUERY: #{inspect(Repo.one(query))}")

    case Repo.one(query) do
      nil ->
        no_user_verify()
        {:error, :invalid_credentials}

      user ->
        case check_pass(user, password) do
          {:error, reason} ->
            {:error, reason}

          {:ok, _hashed_password} ->
            Logger.info("RETURNED AUTH USER: #{inspect(user)}")
            {:ok, user}
        end
    end
  end

  def spawn_user(user) do
    Logger.info("SPAWN USER ACCOUNT: #{inspect(user)}")
    Supervisor.start_child(user)
  end

  def get_user(username) do
    Users.get_user(username)
  end

  def join_server(username, server_name) do
    Core.add_user_to_server(server_name, username)
  end

  def leave_server(username, server_name) do
    Core.remove_user_from_server(server_name, username)
  end
end
