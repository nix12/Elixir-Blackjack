defmodule Blackjack.Accounts.Users do
  require Logger

  use GenServer

  alias Blackjack.Core
  alias Blackjack.Accounts.AccountsRegistry

  # Client

  def start_link(user_account) do
    IO.inspect(user_account, label: "############# SPAWN ACCOUNT #############")

    case GenServer.start_link(__MODULE__, user_account,
           name: Blackjack.via_horde({AccountsRegistry, user_account.username})
         ) do
      {:ok, pid} ->
        IO.inspect(pid, label: "############# ACCOUNT PID #############")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "#{user_account.username} is already started at #{inspect(pid)}, returning :ignore"
        )

        :ignore
    end
  end

  def get_user(username) do
    IO.inspect(username, label: "GET ACCOUNT")

    IO.inspect(Horde.Registry.whereis_name({Blackjack.Accounts.AccountsRegistry, username}),
      label: "ACCOUNT PID"
    )

    GenServer.call(Blackjack.via_horde({AccountsRegistry, username}), {:get_user})
  end

  # Server

  @impl true
  def init(user_account) do
    IO.inspect("SPAWNING USER ACCOUNT")
    # Handle user crash
    # Process.flag(:trap_exit, true)
    {:ok, user_account}
  end

  @impl true
  def handle_call({:get_user}, _from, user_account) do
    {:reply, user_account, user_account}
  end

  def handle_call({:sync_server, [server_data] = _server}, _from, user_account) do
    {:reply, Core.sync_server(server_data), user_account}
  end

  # @impl true
  # def terminate(_reason, user_account) do
  #   Core.remove_user_from_server(, user_account.username)
  # end
end
