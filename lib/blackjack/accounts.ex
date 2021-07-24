defmodule Blackjack.Accounts do
  alias Blackjack.Accounts.Users

  def spawn_user(username) do
    Users.start_link(username)
  end

  def get_user_by_username!(username) do
    # Returns {user's pid, user}
    Users.get_user_by_username(username)
  end
end
