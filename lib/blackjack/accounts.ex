defmodule Blackjack.Accounts do
  def get_user!(username) do
    # Returns {user's pid, user}
    Blackjack.Accounts.Users.get_user(username)
  end
end
