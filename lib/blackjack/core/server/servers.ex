defmodule Blackjack.Core.Servers do
  @moduledoc """
    Contains actions for servers.
  """
  alias Blackjack.Repo
  alias Blackjack.Accounts.AccountsRegistry
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{CoreRegistry, Server, ServerManager, Servers, ServerQuery}

  # defp start_server(server_name) do
  #   case server_name |> query_servers |> Repo.all() do
  #     [] ->
  #       Logger.error("Failed to start server #{inspect(server_name)}.")

  #     [server] ->
  #       Logger.info("Starting server #{inspect(server.server_name)}.")
  #       # Cachex.put!(Blackjack.Cache, server_name, server)
  #       server
  #   end
  # end

  # def save_state(server) do
  #   StateManager.insert(%{
  #     server_name: server["server_name"],
  #     data: Jason.encode!(server),
  #     inserted_at: DateTime.utc_now(),
  #     updated_at: DateTime.utc_now()
  #   })

  #   State
  # end

  # def load_state(server) do
  #   query =
  #     from(s in "states",
  #       where: [server_name: ^server.server_name],
  #       select: [:server_name, :data]
  #     )

  #   case Repo.all(query) do
  #     [] ->
  #       Logger.info("Failed to retrieve server data for #{inspect(server.server_name)}.")
  #       server.server_name |> start()

  #     [%{server_name: server_name, data: data}] ->
  #       Logger.info("Retreiving server data for #{inspect(server_name)}.")

  #       # Cachex.put!(Blackjack.Cache, server_name, server)
  #       Jason.decode!(data)
  #   end
  # end

  # def player_count(members) do
  #   # server_name
  #   # |> PubSub.subscribers()
  #   # |> Enum.count()

  #   Enum.count(members)
  # end

  def join_server(members, %{uuid: uuid}) do
    [{pid, _}] = Horde.Registry.lookup(AccountsRegistry, uuid)

    Process.link(pid)
    [pid | members]
  end

  def leave_server(members, %{uuid: uuid}) do
    [{pid, _}] = Horde.Registry.lookup(AccountsRegistry, uuid)

    Process.unlink(pid)
    List.delete(members, pid)
  end

  def notify_members(members) do
    # Send updated server through socket
  end

  # def send_update do
  #   :timer.send_interval(10_000, {:update_status})
  # end
end
