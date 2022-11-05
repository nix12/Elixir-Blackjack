defmodule BlackjackWeb.Controllers.AuthenticationController do
  @moduledoc """
    Contains functions for user authentication functions.
  """
  import Plug.Conn
  import Bcrypt

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Notifiers.AccountsNotifier

  @type user :: %User{
          uuid: String.t(),
          email: String.t(),
          username: String.t(),
          password_hash: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
    Finds the user from the database, then checks for a matching password.
    If correct, this functions generates a JWT token to be sent back to the
    client, otherwise return an error conn.
  """
  @spec create(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def create(%{:params => %{"user" => %{"email" => email, "password_hash" => password}}} = conn) do
    user = Repo.get_by(User, email: email)

    cond do
      user && check_pass(user, password) ->
        {:ok, login(conn, user)}

      user ->
        {:error, assign(conn, :error, "unauthorized")}

      true ->
        {:error, assign(conn, :error, "not found")}
    end
  end

  @doc """
    Clears conn of resource information.
  """
  @spec destroy(Plug.Conn.t()) :: Plug.Conn.t()
  def destroy(conn) do
    {:ok, conn |> Guardian.Plug.sign_out()}
  end

  def before_sign_out(conn, _location, _options) do
    Guardian.Plug.current_resource(conn)
    |> AccountsNotifier.publish({:stop_user, []})

    {:ok, conn}
  end

  @spec login(Plug.Conn.t(), user()) :: Plug.Conn.t()
  defp login(conn, user) do
    conn
    |> Guardian.Plug.sign_in(user)
    |> assign_token()
  end

  def after_sign_in(conn, user, _token, _claims, _options) do
    AccountsSupervisor.start_user(user)

    {:ok, conn}
  end

  @spec assign_token(Plug.Conn.t()) :: Plug.Conn.t()
  defp assign_token(conn) do
    user = Guardian.Plug.current_resource(conn)
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, token_type: :access)

    put_resp_header(conn, "authorization", "Bearer " <> token)
  end
end
