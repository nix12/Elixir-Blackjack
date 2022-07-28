defmodule Blackjack.Accounts.FriendshipQuery do
  import Ecto.Query, only: [from: 2]

  alias Blackjack.Accounts.{User, Friendship}

  def pending_friendships(user) do
    from(u in User,
      join: friend in Friendship,
      where: ^user.uuid == friend.user_uuid and friend.pending == true,
      select: u
    )
  end

  def accepted_friendships(user) do
    from(u in User,
      join: friend in Friendship,
      where: ^user.uuid == friend.user_uuid and friend.pending == false,
      select: u
    )
  end
end
