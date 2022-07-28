defmodule Blackjack.Accounts.Policy do
  @behaviour Bodyguard.Policy

  alias Blackjack.Accounts.User

  def authorize(:update_user, %User{} = user, uuid)
      when user.uuid == uuid,
      do: true

  def authorize(:show_user, %User{}, %User{}), do: true

  def authorize(:create_friendship, %User{} = user, %User{} = user2) when user.uuid != user2.uuid,
    do: true

  def authorize(:remove_friendship, %User{} = user, %User{} = user2) when user.uuid != user2.uuid,
    do: true

  def authorize(_action, _user, _), do: :error
end
