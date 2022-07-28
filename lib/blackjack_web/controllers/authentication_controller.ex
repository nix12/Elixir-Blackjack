defmodule BlackjackWeb.Controllers.AuthenticationController do
  import Plug.Conn
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor

  @spec create(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def create(%{:params => %{"user" => %{"email" => email, "password_hash" => password}}} = conn) do
    user = Repo.get_by(User, email: email)

    cond do
      user && check_pass(user, password) ->
        {:ok, login(conn, user)}

      user ->
        conn = assign(conn, :error, "unauthorized")
        {:error, conn}

      true ->
        conn = assign(conn, :error, "not found")
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
    |> assign_token(user)
    |> tap(fn _conn ->
      AccountsSupervisor.start_user(user)
    end)
  end

  def assign_token(conn, user) do
    {:ok, token, _} = Guardian.encode_and_sign(user, %{}, token_type: :access)

    put_resp_header(conn, "authorization", "Bearer " <> token)
  end
end
