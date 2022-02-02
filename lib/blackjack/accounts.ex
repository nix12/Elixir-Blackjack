defmodule Blackjack.Accounts do
  alias Blackjack.Core
  alias Blackjack.Accounts.{Users, Supervisor}

  def spawn_user(user) do
    Supervisor.start_child(user)
  end

  def get_user(username) do
    Users.get_user(username)
  end

  def join_server(username, server_name) do
    Core.add_user_to_server(server_name, username)
  end

  def leave_server(username, server_name) do
    Core.remove_user_from_server(server_name, username)
  end
end
