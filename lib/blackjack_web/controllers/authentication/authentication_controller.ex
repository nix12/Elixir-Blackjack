defmodule BlackjackWeb.Controllers.AuthenticationController do
  import Plug.Conn
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Notifications.AccountsNotifier

  @spec create(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def create(
        %{:params => %{"user" => %{"username" => username, "password_hash" => password}}} = conn
      ) do
    user = Repo.get_by(User, username: username)

    cond do
      user && check_pass(user, password) ->
        {:ok, login(conn, user)}

      user ->
        conn = assign(conn, :error, :unauthorized)
        {:error, conn}

      true ->
        conn = assign(conn, :error, :not_found)
        {:error, conn}
    end
  end

  @spec delete(Plug.Conn.t()) :: Plug.Conn.t()
  def delete(conn) do
    Guardian.Plug.sign_out(conn)
  end

  defp login(conn, user) do
    conn
    |> Guardian.Plug.sign_in(user)
    |> assign_current_user(user)
    |> assign_token()
    |> tap(fn _conn ->
      AccountsNotifier.publish(user |> Map.put(:mod, AccountsSupervisor), {:start_user, user})
    end)
  end

  def assign_token(conn) do
    assign(conn, :key, %{"Authorization" => "Bearer #{Guardian.Plug.current_token(conn)}"})
  end

  def assign_current_user(conn, user) do
    assign(conn, :current_user, user)
  end
end
