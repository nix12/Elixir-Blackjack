defmodule Blackjack.Accounts.UserManager do
  @moduledoc """
    Controls the process and actions of the current user.
  """
  require Logger

  use GenServer

  alias Blackjack.Accounts.{
    User,
    Friendships,
    AccountsRegistry
  }

  alias Blackjack.Repo
  alias Blackjack.Accounts.Inbox.InboxesNotifications
  alias Blackjack.Communications.Notifications.Notification

  # Client

  @spec start_link(map()) :: {:ok, pid()} | no_return()
  def start_link(user_account) do
    case GenServer.start_link(__MODULE__, user_account,
           name: Blackjack.via_horde({AccountsRegistry, user_account.uuid})
         ) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "#{user_account.username} is already started at #{inspect(pid)}, returning :ignore"
        )

        :ignore
    end
  end

  @spec get_user(binary()) :: map()
  def get_user(uuid) do
    GenServer.call(Blackjack.via_horde({AccountsRegistry, uuid}), {:get_user})
  end

  # Server

  @impl true
  def init(user_account) do
    # Handle user crash
    Process.flag(:trap_exit, true)

    {:ok, user_account}
  end

  @impl true
  def handle_call({:get_user}, _from, user_account) do
    {:reply, user_account, user_account}
  end

  @impl true
  def handle_info({:update_user, [user]}, user_account) do
    case user_account |> Repo.reload() |> User.changeset(user) |> Repo.update() do
      {:ok, updated_user} ->
        {:noreply, updated_user}

      {:error, _changeset} ->
        {:noreply, %{user_account | error: "Failed to update account. Please try again."}}
    end
  end

  def handle_info({:stop_user, _}, user_account) do
    {:stop, :normal, user_account}
  end

  def handle_info({:create_friendship, [requested_user]}, user_account) do
    case Friendships.create_friendships(user_account, requested_user) do
      {:ok, friendship} ->
        Friendships.send_success(:create, user_account, requested_user, friendship)
        send(self(), {:friend_request, requested_user})
        {:noreply, user_account}

      {:error, error} ->
        Friendships.send_error(:create, user_account, requested_user, error)

        {:noreply, user_account}
    end
  end

  def handle_info({:friend_request, requested_user}, user_account) do
    notification = %Notification{
      user_uuid: requested_user.uuid,
      body: "Friend request from: " <> user_account.username
    }

    %InboxesNotifications{
      inbox: requested_user |> Repo.preload(:inbox) |> Map.get(:inbox),
      notification: notification
    }
    |> Repo.insert()

    Logger.info("Friend request sent to: " <> requested_user.username)
    {:noreply, user_account}
  end

  def handle_info({:accept_friendship, [requested_user]}, user_account) do
    case Friendships.update_friendship(user_account, requested_user) do
      {:ok, friendship} ->
        Friendships.send_success(:accept, user_account, requested_user, friendship)
        {:noreply, user_account}

      {:error, error} ->
        Friendships.send_error(:accept, user_account, requested_user, error)
        {:noreply, user_account}
    end
  end

  def handle_info({:decline_friendship, [requested_user]}, user_account) do
    case Friendships.remove_friendship(user_account, requested_user) do
      {:ok, friendship} ->
        Friendships.send_success(:decline, user_account, requested_user, friendship)
        {:noreply, user_account}

      {:error, error} ->
        Friendships.send_error(:decline, user_account, requested_user, error)
        {:noreply, user_account}
    end
  end

  def handle_info({:remove_friendship, [requested_user]}, user_account) do
    case Friendships.remove_friendship(user_account, requested_user) do
      {:ok, friendship} ->
        Friendships.send_success(:remove, user_account, requested_user, friendship)
        {:noreply, user_account}

      {:error, error} ->
        Friendships.send_error(:remove, user_account, requested_user, error)
        {:noreply, user_account}
    end
  end

  @impl true
  def terminate(_reason, user_account) do
    Logger.info("Stopping user -> #{user_account.uuid}: #{user_account.username}")
  end
end
