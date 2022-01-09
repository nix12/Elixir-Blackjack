defmodule Blackjack.NodeObserver do
  require Logger
  use GenServer

  alias Blackjack.Accounts.AccountsRegistry
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Core
  alias Blackjack.Core.CoreRegistry
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  @impl true
  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    Logger.info("Accounts Observer started.")
    {:ok, nil}
  end

  @impl true
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_members(AccountsRegistry)
    set_members(CoreRegistry)
    set_members(AccountsSupervisor)
    set_members(CoreSupervisor)

    Logger.info("--------------> NODE UP 2 <--------------")

    {:noreply, state, {:continue, :log}}
  end

  @impl true
  def handle_info({:nodedown, _node, _node_type}, state) do
    set_members(AccountsRegistry)
    set_members(CoreRegistry)
    set_members(AccountsSupervisor)
    set_members(CoreSupervisor)

    Logger.info("--------------> NODE DOWN 2 <--------------")

    {:noreply, state}
  end

  @impl true
  def handle_continue(:log, state) do
    Logger.info("CORE REGISTRY: #{inspect(Horde.Cluster.members(CoreRegistry))}")
    Logger.info("CORE SUPERVISOR: #{inspect(Horde.Cluster.members(CoreSupervisor))}")

    # Logger.info("SERVER(seventh) MEMBERSHIP: #{inspect(Horde.Cluster.members("seventh"))}")

    # Logger.info("ACCOUNTS: #{inspect(Horde.Cluster.members(Blackjack.Accounts.Supervisor))}")

    {:noreply, state}
  end

  defp set_members(name) do
    members =
      [Node.self() | Node.list()]
      |> Enum.map(fn node -> {name, node} end)

    :ok = Horde.Cluster.set_members(name, members)
  end
end
