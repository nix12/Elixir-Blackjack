defmodule Blackjack.Accounts.FriendshipQuery do
  @moduledoc """
    Contains query functions for returning friendships using the
    friendship model and friends using the user model.
  """
  import Ecto.Query, only: [from: 2]

  alias Blackjack.Accounts.{User, Friendship}

  @type user :: %User{
          id: String.t(),
          email: String.t(),
          username: String.t(),
          password_hash: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
    Returns a pending friendship based on the current user and
    requested user.
  """
  @spec pending_friendship(user(), user()) :: Ecto.Query.t()
  def pending_friendship(current_user, requested_user) do
    from(
      friendships in Friendship,
      where:
        (friendships.pending == true and
           (friendships.friend_id == ^requested_user.id and
              friendships.user_id == ^current_user.id)) or
          (friendships.friend_id == ^current_user.id and
             friendships.user_id == ^requested_user.id)
    )
  end

  @doc """
    Returns a accepted friendship based on the current user and
    requested user.
  """
  @spec accepted_friendship(user(), user()) :: Ecto.Query.t()
  def accepted_friendship(current_user, requested_user) do
    from(
      friendships in Friendship,
      where:
        (friendships.accepted == true and
           (friendships.friend_id == ^requested_user.id and
              friendships.user_id == ^current_user.id)) or
          (friendships.friend_id == ^current_user.id and
             friendships.user_id == ^requested_user.id)
    )
  end

  @doc """
    Returns the current user's pending friendships.
  """
  @spec pending_friendships(user()) :: Ecto.Query.t()
  def pending_friendships(current_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.pending == true and friendships.friend_id == ^current_user.id,
      select: friendships
    )
  end

  @doc """
    Returns the current user's accepted friendships.
  """
  @spec accepted_friendships(user()) :: Ecto.Query.t()
  def accepted_friendships(current_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.accepted == true and friendships.friend_id == ^current_user.id,
      select: friendships
    )
  end

  @doc """
    Returns all (pending and accepted) the friendships for the current user.
  """
  @spec all_friendships(user()) :: Ecto.Query.t()
  def all_friendships(current_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.friend_id == ^current_user.id,
      select: friendships
    )
  end

  @doc """
    Returns the pending users that are in a friendship with the current user.
  """
  @spec pending_friends(user()) :: Ecto.Query.t()
  def pending_friends(current_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.pending == true and friendships.friend_id == ^current_user.id
    )
  end

  @doc """
    Returns the accepted users that are in a friendship with the current user.
  """
  @spec accepted_friends(user()) :: Ecto.Query.t()
  def accepted_friends(current_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.accepted == true and friendships.friend_id == ^current_user.id
    )
  end

  @doc """
    Returns the inverse of pending_friends/1.
  """
  @spec pending_received_friends(user()) :: Ecto.Query.t()
  def pending_received_friends(requested_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.pending == true and friendships.user_id == ^requested_user.id
    )
  end

  @doc """
    Returns the inverse of accepted_friends/1.
  """
  @spec accepted_received_friends(user()) :: Ecto.Query.t()
  def accepted_received_friends(requested_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.accepted == true and friendships.user_id == ^requested_user.id
    )
  end

  @doc """
    Returns all users (pending and accepted) that are in a friendship with the current user.
  """
  @spec all_friends(user()) :: Ecto.Query.t()
  def all_friends(current_user) do
    from(user in User,
      left_join: friendships in Friendship,
      on: friendships.user_id == user.id,
      where: friendships.friend_id == ^current_user.id
    )
  end
end
