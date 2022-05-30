defmodule Blackjack.Accounts do
  alias Blackjack.Core
  alias Blackjack.Accounts.AccountsServer
  alias Blackjack.Notifications.AccountsNotifier

  # def start_user(user) do
  #   AccountsSupervisor.start_child(user)
  # end

  def join_server(username, server_name) do
    Core.add_user_to_server(server_name, username)
  end

  def leave_server(username, server_name) do
    Core.remove_user_from_server(server_name, username)
  end
end
