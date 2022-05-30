defmodule BlackjackWeb.Controllers.UsersController do
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.{User, UserManager}
  alias Blackjack.Notifications.AccountsNotifier

  def update(conn) do
    user = conn.params["current_user"]
    AccountsNotifier.publish(user |> Map.put(:mod, UserManager), {:update_user, user})
    updated_user = Repo.get(User, user["uuid"])

    {:ok, assign(conn, :current_user, updated_user)}
  end
end
