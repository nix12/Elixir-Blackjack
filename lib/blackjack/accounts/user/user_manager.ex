defmodule Blackjack.Accounts.UserManager do
  require Logger

  use GenServer

  alias Blackjack.Repo
  alias Blackjack.Accounts.{User, Friendship, Friendships, AccountsRegistry}
  alias Blackjack.Accounts.Inbox.Notifications.Notification

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
  @spec init(map()) :: {:ok, map()}
  def init(user_account) do
    # Handle user crash
    # Process.flag(:trap_exit, true)

    {:ok, user_account}
  end

  @impl true
  def handle_call({:get_user}, _from, user_account) do
    {:reply, user_account, user_account}
  end

  @impl true
  def handle_info({:update_user, [user]}, user_account) do
    case User.changeset(user_account, user) |> Repo.update() do
      {:ok, updated_user} ->
        {:noreply, updated_user}

      {:error, _changeset} ->
        {:noreply, %{user_account | error: "Failed to update account. Please try again."}}
    end
  end

  def handle_info({:create_friendship, [requested_user]}, user_account) do
    case Friendship.changeset(%Friendship{}, %{
           user_uuid: user_account.uuid,
           friend_uuid: requested_user.uuid
         })
         |> Repo.insert() do
      {:ok, _pending_friendship} ->
        send(self(), {:friend_request, requested_user})
        {:noreply, user_account}

      {:error, _changeset} ->
        {:noreply, %{user_account | error: "Failed to send friend request. Please try again."}}
    end
  end

  def handle_info({:friend_request, requested_user}, user_account) do
    Notification.changeset(%Notification{}, %{
      user_uuid: user_account.uuid,
      recipient_uuid: requested_user.uuid,
      body: "Friend request from: " <> user_account.username
    })

    {:noreply, user_account}
  end

  @impl true
  def terminate(reason, state) do
    IO.inspect(reason, label: "TERMINATE")
  end
end
