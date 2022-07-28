defmodule BlackjackWeb.Controllers.UsersController do
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.{User, UserManager, Policy}
  alias Blackjack.Notifier.AccountsNotifier

  def update(%{params: %{"user" => user, "uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)

    with :ok <- Bodyguard.permit(Policy, :update_user, current_user, uuid) do
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
      {:error, error} -> {:error, assign(conn, :error, error)}
    end
  end

  def show(%{params: %{"uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Repo.get(User, uuid)

    with :ok <- Bodyguard.permit(Policy, :show_user, current_user, user) do
      {:ok, assign(conn, :user, user)}
    else
      {:error, error} -> {:error, assign(conn, :error, error)}
    end
  end
end
