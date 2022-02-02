defmodule BlackjackCli.Controllers.AuthenticationController do
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts
  alias Blackjack.Accounts.Authentication.Guardian

  def create(
        %{:params => %{"user" => %{"username" => username, "password_hash" => password}}} = conn
      ) do
    case authenticate_user(username, password) do
      {:error, message} ->
        conn = assign(conn, :errors, message)
        {:error, conn}

      {:ok, user} ->
        conn =
          conn
          |> Guardian.Plug.sign_in(user)
          |> assign(:user, user)
          |> then(&assign(&1, :token, Guardian.Plug.current_token(&1)))
          |> tap(&spawn_user(&1))
          |> tap(&get_user(&1))

        {:ok, conn}
    end
  end

  def delete(conn) do
    Guardian.Plug.sign_out(conn)
  end

  defp spawn_user(conn) do
    Accounts.spawn_user(conn.assigns.user)
  end

  defp get_user(conn) do
    Accounts.get_user(conn.assigns.user.username)
  end

  defp authenticate_user(username, password) do
    IO.inspect({username, password}, label: "LOGIN CREDENTIALS")
    IO.inspect(Application.get_env(:blackjack, Blackjack.Repo))

    # Repo.insert(%Blackjack.Accounts.User{username: "user", password_hash: "password"})
    # |> tap(&IO.inspect(&1, label: "=====> MAIN APP <====="))

    IO.inspect(Repo.all(Blackjack.Accounts.User), label: "ALL USERS")

    query =
      from(u in Blackjack.Accounts.User,
        where: u.username == ^username,
        select: %{
          username: u.username,
          password_hash: u.password_hash,
          uuid: type(u.uuid, :string),
          inserted_at: u.inserted_at,
          updated_at: u.updated_at
        }
      )

    IO.inspect(Repo.all(query), label: "ALL USERS")

    IO.inspect(Repo.exists?(query),
      label: "RETURN USER ACCOUNTS"
    )

    case Repo.one(query) do
      nil ->
        no_user_verify()
        {:error, "invalid credentials"}

      user ->
        IO.inspect(user, label: "=====> CHECK PASS <=====")

        case check_pass(user, password) do
          {:error, reason} ->
            {:error, reason}

          {:ok, _hashed_password} ->
            {:ok, user}
        end
    end
  end
end
