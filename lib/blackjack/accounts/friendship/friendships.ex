defmodule Blackjack.Accounts.Friendships do
  @moduledoc """
    Contains functions that support actions in the user manager friendships.
  """
  require Logger

  alias Blackjack.Repo
  alias Blackjack.Accounts.{User, Friendship}

  @type user :: %User{
          uuid: String.t(),
          email: String.t(),
          username: String.t(),
          password_hash: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type friendship :: %Friendship{
          user_uuid: String.t(),
          friend_uuid: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
    Creates a friendship between the current user and the requested user,
    as well as, the inverse of the friendship in one transaction.
  """
  @spec create_friendships(user(), user()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def create_friendships(current_user, requested_user) do
    friendship_changeset =
      Friendship.changeset(%Friendship{}, %{
        user_uuid: current_user.uuid,
        friend_uuid: requested_user.uuid
      })

    inverse_friendship =
      Friendship.changeset(%Friendship{}, %{
        user_uuid: requested_user.uuid,
        friend_uuid: current_user.uuid
      })

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_friendship, friendship_changeset)
    |> Ecto.Multi.insert(:inverse_friendship, inverse_friendship)
    |> Repo.transaction()
    |> case do
      {:ok, _success} = transaction ->
        transaction

      {:error, _name, %{errors: errors}, _changes} ->
        {:error, errors}
    end
  end

  @doc """
    Updates the current user's friendship with the requested user, as well as,
    the inverse to show an accepted status of true and a pending status of
    false. This is done in a single transaction.
  """
  @spec update_friendship(user(), user()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def update_friendship(current_user, requested_user) do
    with {:ok, friendship} <- get_friendship(current_user, requested_user),
         {:ok, received_friendship} <- get_friendship(requested_user, current_user) do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:update_current_user_friendship, friendship)
      |> Ecto.Multi.update(:update_requested_user_friendship, received_friendship)
      |> Repo.transaction()
    else
      _ -> {:error, {:failed_update, :user_not_found}}
    end
  end

  @doc """
    Removes the current user's friendship with the requested user, as well as,
    the inverse to show an accepted status of true and a pending status of
    false. This is done in a single transaction.
  """
  @spec remove_friendship(user(), user()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def remove_friendship(current_user, requested_user) do
    with {:ok, friendship} <- get_friendship(current_user, requested_user),
         {:ok, received_friendship} <- get_friendship(requested_user, current_user) do
      Ecto.Multi.new()
      |> Ecto.Multi.delete(:remove_current_user_friendship, friendship)
      |> Ecto.Multi.delete(:remove_requested_user_friendship, received_friendship)
      |> Repo.transaction()
    else
      _ -> {:error, {:failed_delete, :user_not_found}}
    end
  end

  defp get_friendship(current_user, requested_user) do
    case Repo.get_by(Friendship, user_uuid: current_user.uuid, friend_uuid: requested_user.uuid) do
      nil ->
        {:error, :failed_operation}

      friendship ->
        {:ok, friendship |> Ecto.Changeset.change(pending: false, accepted: true)}
    end
  end

  @doc """
    Sends and logs successes pertaining to the creation of a friendship.
  """
  @spec send_success(atom(), user(), user(), friendship()) :: :ok
  def send_success(:create, current_user, requested_user, friendship) do
    send(
      {:"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}", node()},
      {:ok, friendship}
    )

    Logger.info(
      "Friendship created between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
    )
  end

  def send_success(:accept, current_user, requested_user, friendship) do
    send(
      {:"accept_friendship_#{current_user.uuid}_to_#{requested_user.uuid}", node()},
      {:ok, friendship}
    )

    Logger.info(
      "Friendship accepted between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
    )
  end

  def send_success(:decline, current_user, requested_user, friendship) do
    send(
      {:"decline_friendship_#{current_user.uuid}_to_#{requested_user.uuid}", node()},
      {:ok, friendship}
    )

    Logger.info(
      "Friendship declined between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
    )
  end

  def send_success(:remove, current_user, requested_user, friendship) do
    send(
      {:"remove_friendship_#{current_user.uuid}_to_#{requested_user.uuid}", node()},
      {:ok, friendship}
    )

    Logger.info(
      "Friendship removal between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
    )
  end

  @doc """
    Sends and logs errors pertaining to friendship actions.
  """
  @spec send_error(atom(), user(), user(), any()) :: :ok
  def send_error(
        :create,
        current_user,
        requested_user,
        [{field_or_name, {error_message, constraint}}]
      ) do
    case constraint do
      [] ->
        IO.inspect(error_message, label: "ERROR1")

        send(
          {:"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}", node()},
          {:error, error_message}
        )

        Logger.error(
          "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
            error_message
        )

      constraint when constraint |> is_nil() == false ->
        IO.inspect(error_message, label: "ERROR2")

        Logger.error(
          "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
            (field_or_name
             |> Atom.to_string()) <> " " <> error_message
        )

        send(
          {:"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}", node()},
          {:error, "#{field_or_name |> Atom.to_string()} #{error_message}."}
        )
    end
  end

  def send_error(:accept, current_user, requested_user, {_type, reason} = error) do
    send(
      :"accept_friendship_#{current_user.uuid}_to_#{requested_user.uuid}",
      {:error,
       "Failed to accept friend request because #{reason |> Atom.to_string() |> String.replace("_", " ")}. Please try again later."}
    )

    Logger.error(
      "Accept friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
        inspect(error)
    )
  end

  def send_error(:decline, current_user, requested_user, {_type, reason} = error) do
    send(
      :"decline_friendship_#{current_user.uuid}_to_#{requested_user.uuid}",
      {:error,
       "Failed to decline friend request because #{reason |> Atom.to_string() |> String.replace("_", " ")}. Please try again later."}
    )

    Logger.error(
      "Friendship declined error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
        inspect(error)
    )
  end

  def send_error(:remove, current_user, requested_user, {_type, _reason} = error) do
    send(
      :"remove_friendship_#{current_user.uuid}_to_#{requested_user.uuid}",
      {:error, "Failed to remove friend request because user not found. Please try again later."}
    )

    Logger.error(
      "Friendship removal error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
        inspect(error)
    )
  end
end
