defmodule Blackjack.Policy do
  @moduledoc """
    Application policies pertaining to authorization.
  """
  @behaviour Bodyguard.Policy

  alias Blackjack.Accounts.{User, Friendship}

  def authorize(:update_user, %User{} = user, uuid)
      when user.uuid == uuid,
      do: :ok

  def authorize(:show_user, %User{}, %User{}), do: :ok

  def authorize(:create_friendship, %User{}, %Friendship{}), do: :ok

  def authorize(:accept_friendship, %User{uuid: uuid}, %Friendship{
        user_uuid: user_uuid
      })
      when uuid == user_uuid,
      do: :ok

  def authorize(:decline_friendship, %User{uuid: uuid}, %Friendship{user_uuid: user_uuid})
      when uuid == user_uuid,
      do: :ok

  def authorize(:remove_friendship, %User{uuid: uuid}, %Friendship{user_uuid: user_uuid})
      when uuid == user_uuid,
      do: :ok

  def authorize(_action, _, _), do: :error
end
