defmodule BlackjackWeb.Controllers.UsersController do
  @moduledoc """
    Contains CRUD actions for user.
  """
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Policy
  alias Blackjack.Accounts.{User, UserManager}
  alias Blackjack.Notifiers.AccountsNotifier

  @doc """
    Updates the current user or returns an error conn
  """
  @spec update(Plug.Conn.t()) :: {:ok, Plug.Conn.t()} | {:error, Plug.Conn.t()}
  def update(%{params: %{"user" => user}, path_params: %{"uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)

    with true <- Guardian.Plug.authenticated?(conn),
         :ok <- Bodyguard.permit(Policy, :update_user, current_user, uuid) do
      AccountsNotifier.publish(current_user, {:update_user, user})
      :timer.sleep(50)

      updated_user = UserManager.get_user(current_user.uuid)

      if updated_user.error do
        {:error, assign(conn, :error, updated_user.error)}
      else
        conn
        |> Guardian.Plug.current_token()
        |> Guardian.revoke()

        conn = Guardian.Plug.sign_in(conn, updated_user)
        token = Guardian.Plug.current_token(conn)

        {:ok, put_resp_header(conn, "authorization", "Bearer " <> token)}
      end
    else
      {:error, reason} ->
        {:error, assign(conn, :error, reason)}

      error ->
        {:error, assign(conn, :error, error)}
    end
  end

  @doc """
    Gets the user resource.
  """
  @spec show(Plug.Conn.t()) :: {:ok, Plug.Conn.t()} | {:error, Plug.Conn.t()}
  def show(%{path_params: %{"uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)
    requested_user = Repo.get(User, uuid)

    with true <- Guardian.Plug.authenticated?(conn),
         :ok <- Bodyguard.permit(Policy, :show_user, current_user, requested_user) do
      {:ok, assign(conn, :user, requested_user)}
    else
      {:error, reason} ->
        {:error, assign(conn, :error, reason)}

      error ->
        {:error, assign(conn, :error, error)}
    end
  end
end
