defmodule Blackjack.Accounts.UserManager do
  @moduledoc """
    Controls the process and actions of the current user.
  """
  require Logger

  use GenServer

  alias Blackjack.Accounts.{
    User,
    Users,
    Friendships,
    AccountsRegistry
  }

  alias Blackjack.Repo
  alias Blackjack.Accounts.Inbox.{InboxesNotifications, InboxesConversations}
  alias Blackjack.Communications.Notifications.Notification
  alias Blackjack.Communications.Conversations.{Conversation, Conversations}
  alias Blackjack.Communications.Messages.{Message, Messages}
  alias Blackjack.Core.Server
  alias Blackjack.Core.Supervisor, as: CoreSupervisor

  # Client

  @spec start_link(map()) :: {:ok, pid()} | no_return()
  def start_link(user_account) do
    case GenServer.start_link(__MODULE__, user_account,
           name: Blackjack.via_horde({AccountsRegistry, user_account.id})
         ) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "#{user_account.username} is already started at #{inspect(pid)}, shutting down previous instance."
        )

        [{old_pid, _}] = Horde.Registry.lookup(AccountsRegistry, user_account.id)
        Process.exit(old_pid, :kill)

        {:ok, pid}
    end
  end

  @spec get_user(binary()) :: map()
  def get_user(id) do
    GenServer.call(Blackjack.via_horde({AccountsRegistry, id}), {:get_user})
  end

  def get_friends(id) do
    GenServer.call(Blackjack.via_horde({AccountsRegistry, id}), {:get_friends})
  end

  def create_friendship(%{"id" => id}, requested_user) do
    GenServer.call(
      Blackjack.via_horde({AccountsRegistry, id}),
      {:create_friendship, requested_user}
    )
  end

  def accept_friendship(%{"id" => id}, requested_user) do
    GenServer.call(
      Blackjack.via_horde({AccountsRegistry, id}),
      {:create_friendship, requested_user}
    )
  end

  def decline_friendship(%{"id" => id}, requested_user) do
    GenServer.call(
      Blackjack.via_horde({AccountsRegistry, id}),
      {:decline_friendship, requested_user}
    )
  end

  def remove_friendship(%{"id" => id}, requested_user) do
    GenServer.call(
      Blackjack.via_horde({AccountsRegistry, id}),
      {:remove_friendship, requested_user}
    )
  end

  def create_message(%{"id" => id}, requested_user, message) do
    GenServer.call(
      Blackjack.via_horde({AccountsRegistry, id}),
      {:create_message, requested_user, message}
    )
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

  def handle_call({:get_friends}, _from, user_account) do
    friends = user_account |> Repo.preload(:friends) |> Map.get(:friends)

    Logger.info("LIST OF USER #{user_account.username} friends -> #{inspect(friends)}")

    {:reply, %{friends: friends}, user_account}
  end

  def handle_call({:create_friendship, requested_user}, _from, user_account) do
    case Friendships.create_friendships(user_account, requested_user) do
      {:ok, friendship} = created_friendship ->
        Friendships.send_success(:create, user_account, requested_user, friendship)
        send(self(), {:friend_request, requested_user})
        {:reply, created_friendship, user_account}

      {:error, error} ->
        Friendships.send_error(:create, user_account, requested_user, error)
        {:reply, error, user_account}
    end
  end

  def handle_call({:accept_friendship, requested_user}, _from, user_account) do
    case Friendships.update_friendship(user_account, requested_user) do
      {:ok, friendship} = accepted_friendship ->
        Friendships.send_success(:accept, user_account, requested_user, friendship)
        {:reply, accepted_friendship, user_account}

      {:error, error} ->
        Friendships.send_error(:accept, user_account, requested_user, error)
        {:reply, error, user_account}
    end
  end

  def handle_call({:decline_friendship, requested_user}, _from, user_account) do
    case Friendships.remove_friendship(user_account, requested_user) do
      {:ok, friendship} = declined_friendship ->
        Friendships.send_success(:decline, user_account, requested_user, friendship)
        {:reply, declined_friendship, user_account}

      {:error, error} ->
        Friendships.send_error(:decline, user_account, requested_user, error)
        {:reply, error, user_account}
    end
  end

  def handle_call({:remove_friendship, requested_user}, _from, user_account) do
    case Friendships.remove_friendship(user_account, requested_user) do
      {:ok, friendship} = removed_friendship ->
        Friendships.send_success(:remove, user_account, requested_user, friendship)
        {:reply, removed_friendship, user_account}

      {:error, error} ->
        Friendships.send_error(:remove, user_account, requested_user, error)
        {:reply, error, user_account}
    end
  end

  def handle_call({:create_message, requested_user, message}, _from, user_account) do
    {:ok, _} = Conversations.create_or_continue_conversation(user_account, requested_user)

    case Messages.create_message(message) do
      {:ok, _new_message} ->
        send(self(), {:send_message, requested_user})
        {:reply, "Message sent.", user_account}

      {:error, _changeset} ->
        {:reply, "Error: Message not sent.", user_account}
    end
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
    IO.puts("<===== STOP HERE =====>")
    {:stop, :normal, user_account}
  end

  def handle_info({:friend_request, requested_user}, user_account) do
    notification = %Notification{
      from: requested_user.id,
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

  def handle_info({:send_message, requested_user}, user_account) do
    conversation =
      Repo.get_by(Conversation, user_id: user_account.id, recipient_id: requested_user.id)

    Users.insert_conversation_into_inboxes(user_account, requested_user, conversation)

    Logger.info("Message sent to: " <> requested_user.username)
    {:noreply, user_account}
  end

  def handle_info({:start_server, [server_name]}, user_account) do
    Repo.one(Server, server_name: server_name) |> CoreSupervisor.start_server()

    {:noreply, user_account}
  end

  @impl true
  def terminate(_reason, user_account) do
    Logger.info("Stopping user -> #{user_account.id}: #{user_account.username}")
  end
end
