defmodule BlackjackCli.Controllers.AuthenticationController do
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts
  alias Blackjack.Accounts.Authentication.Guardian

  @spec create(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
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

  @spec delete(Plug.Conn.t()) :: Plug.Conn.t()
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
    case username |> query_users() |> Repo.one() do
      nil ->
        no_user_verify()
        {:error, "invalid credentials"}

      user ->
        case check_pass(user, password) do
          {:error, reason} ->
            {:error, reason}

          {:ok, _hashed_password} ->
            {:ok, user}
        end
    end
  end

  defp query_users(username) do
    from(u in "users",
      where: u.username == ^username,
      select: %{
        username: u.username,
        password_hash: u.password_hash,
        uuid: type(u.uuid, :string),
        inserted_at: u.inserted_at,
        updated_at: u.updated_at
      }
    )
  end
end
