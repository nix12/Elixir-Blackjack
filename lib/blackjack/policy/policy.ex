defmodule Blackjack.Policy do
  @moduledoc """
    Application policies pertaining to authorization.
  """
  @behaviour Bodyguard.Policy

  alias Blackjack.Accounts.{User, Friendship, Inbox}
  alias Blackjack.Communications.Conversations.Conversation

  # User
  def authorize(:update_user, %User{} = user, id)
      when user.id == id,
      do: :ok

  def authorize(:show_user, %User{}, %User{}), do: :ok

  # Friendship
  def authorize(:read_friendships, %{"id" => id}, id), do: :ok

  def authorize(:create_friendship, %{"id" => _id}, _), do: :ok

  def authorize(:accept_friendship, %User{id: id}, %Friendship{
        user_id: user_id
      })
      when id == user_id,
      do: :ok

  def authorize(:decline_friendship, %User{id: id}, %Friendship{user_id: user_id})
      when id == user_id,
      do: :ok

  def authorize(:remove_friendship, %User{id: id}, %Friendship{user_id: user_id})
      when id == user_id,
      do: :ok

  # Inbox
  def authorize(:read_inbox, %{"id" => id}, %Inbox{user_id: id}), do: :ok
  def authorize(:create_message, %{"id" => _id}, _), do: :ok

  def authorize(_action, _, _), do: :error
end
