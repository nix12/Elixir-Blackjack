defmodule BlackjackWeb.Controllers.FriendshipsController do
  @moduledoc """
    Contains CRUD actions for friendship model.
  """
  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Accounts.{User, Friendship}
  alias Blackjack.Notifiers.AccountsNotifier
  alias Blackjack.Policy

  @doc """
    Routes incoming messages to the Accounts Notifiers for the creation
    of a new friendship.
  """
  @spec create(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def create(%{params: %{"uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)

    with %User{} = requested_user <- Repo.get(User, uuid),
         :ok <- Bodyguard.permit(Policy, :create_friendship, current_user, %Friendship{}) do
      Task.Supervisor.async(Blackjack.TaskSupervisor, fn ->
        Process.register(
          self(),
          :"create_friendship_#{current_user.uuid}_to_#{uuid}"
        )

        AccountsNotifier.publish(current_user, {:create_friendship, requested_user})

        receive do
          {:ok, friendship} ->
            {:ok, assign(conn, :friendship, friendship)}

          {:error, message} ->
            {:error, assign(conn, :error, message)}
        end
      end)
      |> Task.await()
    else
      nil ->
        {:error,
         assign(
           conn,
           :error,
           "Failed to create friendship, the requested user does not exist. Please try again later."
         )}
    end
  end

  @doc """
    Routes incoming messages to the Accounts Notifiers to accept a friendship.
  """
  @spec accept(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def accept(%{path_params: %{"friend_uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)

    with %User{} = requested_user <- Repo.get(User, uuid),
         %Friendship{} = friendship <-
           Repo.get_by(Friendship, user_uuid: current_user.uuid, friend_uuid: uuid),
         :ok <- Bodyguard.permit(Policy, :accept_friendship, current_user, friendship) do
      Task.Supervisor.async(Blackjack.TaskSupervisor, fn ->
        Process.register(
          self(),
          :"accept_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
        )

        AccountsNotifier.publish(current_user, {:accept_friendship, requested_user})

        receive do
          {:ok, friendship} ->
            {:ok, assign(conn, :friendship, friendship)}

          {:error, message} ->
            {:error, assign(conn, :error, message)}
        end
      end)
      |> Task.await()
    else
      nil ->
        {:error,
         assign(
           conn,
           :error,
           "Failed to create friendship, the requested user does not exist. Please try again later."
         )}
    end
  end

  @doc """
    Routes incoming messages to the Accounts Notifiers to decline a friendship.
  """
  @spec decline(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def decline(%{path_params: %{"friend_uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)

    with %User{} = requested_user <- Repo.get(User, uuid),
         %Friendship{} = friendship <-
           Repo.get_by(Friendship, user_uuid: current_user.uuid, friend_uuid: uuid),
         :ok <- Bodyguard.permit(Policy, :decline_friendship, current_user, friendship) do
      Task.Supervisor.async(Blackjack.TaskSupervisor, fn ->
        Process.register(
          self(),
          :"decline_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
        )

        AccountsNotifier.publish(current_user, {:decline_friendship, requested_user})

        receive do
          {:ok, friendship} ->
            {:ok, assign(conn, :friendship, friendship)}

          {:error, message} ->
            {:error, assign(conn, :error, message)}
        end
      end)
      |> Task.await()
    else
      nil ->
        {:error,
         assign(
           conn,
           :error,
           "Failed to create friendship, the requested user does not exist. Please try again later."
         )}
    end
  end

  @doc """
    Routes incoming messages to the Accounts Notifiers to remove an existing
    friendship.
  """
  @spec destroy(Plug.Conn.t()) :: {:error, Plug.Conn.t()} | {:ok, Plug.Conn.t()}
  def destroy(%{path_params: %{"friend_uuid" => uuid}} = conn) do
    current_user = Guardian.Plug.current_resource(conn)

    with %User{} = requested_user <- Repo.get(User, uuid),
         %Friendship{} = friendship <-
           Repo.get_by(Friendship, user_uuid: current_user.uuid, friend_uuid: uuid),
         :ok <- Bodyguard.permit(Policy, :remove_friendship, current_user, friendship) do
      Task.Supervisor.async(Blackjack.TaskSupervisor, fn ->
        Process.register(
          self(),
          :"remove_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
        )

        AccountsNotifier.publish(current_user, {:remove_friendship, requested_user})

        receive do
          {:ok, friendship} ->
            {:ok, assign(conn, :friendship, friendship)}

          {:error, message} ->
            {:error, assign(conn, :error, message)}
        end
      end)
      |> Task.await()
    else
      nil ->
        {:error,
         assign(
           conn,
           :error,
           "Failed to create friendship, the requested user does not exist. Please try again later."
         )}
    end
  end
end
