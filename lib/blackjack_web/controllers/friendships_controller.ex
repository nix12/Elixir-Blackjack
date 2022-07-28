defmodule BlackjackWeb.Controllers.FriendshipsController do
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.{User, UserManager, Policy}
  alias Blackjack.Notifier.AccountsNotifier

  def create(%{params: %{"uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)
    requested_user = Repo.get(User, uuid)

    with :ok <- Bodyguard.permit(Policy, :create_friendship, current_user, requested_user) do
      AccountsNotifier.publish(current_user, {:create_friendship, requested_user})
      :timer.sleep(50)

      user_with_friends = UserManager.get_user(current_user.uuid)

      if user_with_friends.error do
        {:error, assign(conn, :error, user_with_friends.error)}
      else
        {:ok, assign(conn, :current_user, user_with_friends |> Repo.preload(:friends))}
      end
    else
      {:error, error} -> {:error, assign(conn, :error, error)}
    end
  end

  def destroy(conn) do
  end
end
