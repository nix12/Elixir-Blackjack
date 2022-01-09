defmodule BlackjackCLI.Controllers.AccountsController do
  require Logger

  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts
  alias Blackjack.Accounts.Authentication.Guardian

  def login(
        %{
          :body_params => %{"user" => %{"username" => username, "password_hash" => password}}
        } = conn
      ) do
    case Accounts.authenticate_user(username, password) do
      {:error, message} ->
        {:error, message}

      {:ok, user} ->
        user =
          conn
          |> Guardian.Plug.sign_in(user)
          |> assign(:user, user)
          |> then(&assign(&1, :token, Guardian.Plug.current_token(&1)))
          |> tap(&spawn_user(&1))
          |> tap(&get_user(&1))
          |> then(&Jason.encode!(&1.assigns))

        Logger.info("ENCODED USER: #{inspect(user)}")

        {:ok, user}
    end
  end

  @spec logout(Plug.Conn.t()) :: Plug.Conn.t()
  def logout(conn) do
    Guardian.Plug.sign_out(conn)
  end

  def create_user(conn) do
    Accounts.register_user(conn)
  end

  def spawn_user(conn) do
    Accounts.spawn_user(conn.assigns.user)
  end

  def get_user(conn) do
    Accounts.get_user(conn.assigns.user.username)
  end

  # Server Stuff

  def join_server(%{body_params: %{"server_name" => server_name, "username" => username}}) do
    Accounts.join_server(username, server_name)
  end

  def leave_server(%{body_params: %{"server_name" => server_name, "username" => username}}) do
    Accounts.leave_server(username, server_name)
  end
end
