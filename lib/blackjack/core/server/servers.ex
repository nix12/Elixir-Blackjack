defmodule Blackjack.Core.Servers do
  alias Blackjack.{Repo, Accounts}
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{CoreRegistry, Server, ServerManager, Servers, ServerQuery, StateManager}

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

  # defp player_count(server_name) do
  #   server_name
  #   |> PubSub.subscribers()
  #   |> Enum.count()
  # end

  def join_server(server_name, user) do
    [{pid, _}] =
      {Blackjack.Accounts.AccountsRegistry, user}
      |> Blackjack.via_horde()
      |> Horde.Registry.whereis()

    PubSub.subscribe(pid, server_name)
  end

  # defp leave_server(server_name, username) do
  #   [{pid, _}] =
  #     {Blackjack.Accounts.AccountsRegistry, username}
  #     |> Blackjack.via_horde()
  #     |> Horde.Registry.whereis()

  #   PubSub.unsubscribe(pid, server_name)
  # end

  # def send_update do
  #   :timer.send_interval(10_000, {:update_status})
  # end
end
