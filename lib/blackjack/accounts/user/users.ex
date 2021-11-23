defmodule Blackjack.Accounts.Users do
  require Logger

  use GenServer

  alias Blackjack.Core

  # Client

  def start_link(user_account) do
    GenServer.start_link(__MODULE__, user_account)
  end

  def get_user(username) do
    GenServer.call(Blackjack.via_swarm(username), {:get_user, username})
  end

  # def join_server(username, server_name) do
  #   GenServer.call(Blackjack.lookup(@registry, username), {:join_server, server_name})
  # end

  # def leave_server(username, server_name) do
  #   GenServer.call(Blackjack.lookup(@registry, username), {:leave_server, server_name})
  # end

  # Server

  @impl true
  def init(user_account) do
    {:ok, user_account}
  end

  @impl true
  def handle_call({:get_user, _username}, _from, user_account) do
    Logger.info("USER ACCOUNT: #{inspect(user_account)}")
    {:reply, user_account, user_account}
  end

  @impl true
  def handle_call({:sync_server, [server_data] = _server}, _from, user_account) do
    {:reply, Core.sync_server(server_data), user_account}
  end

  @impl true
  def handle_call({:swarm, :begin_handoff}, _from, group) do
    Logger.info("BEGIN HANDOFF")
    {:reply, :restart, group}
  end

  @impl true
  def handle_cast({:swarm, :end_handoff, group}, group) do
    Logger.info("END HANDOFF")
    {:noreply, group}
  end

  @impl true
  def handle_cast({:swarm, :resolve_conflict, _group}, group) do
    {:noreply, group}
  end

  @impl true
  def handle_info({:swarm, :die}, group) do
    {:stop, :shutdown, group}
  end

  # @impl true
  # def handle_call({:join_server, server_name}, _from, user_account) do
  #   Core.add_user_to_server(server_name, user_account.user.username)

  #   {:reply, "#{user_account.user.username} joined server #{server_name}", user_account}
  # end

  # @impl true
  # def handle_call({:leave_server, server_name}, _from, user_account) do
  #   Core.remove_user_from_server(server_name, user_account.user.username)

  #   {:reply, "#{user_account.user.username} joined server #{server_name}", user_account}
  # end
end
