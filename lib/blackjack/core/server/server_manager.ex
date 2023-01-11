defmodule Blackjack.Core.ServerManager do
  @moduledoc """
    Manages server processes.
  """
  require Logger

  use GenServer

  alias Blackjack.{Repo, Accounts}
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{CoreRegistry, Server, ServerManager, Servers}

  def start_link(server) do
    case GenServer.start_link(__MODULE__, server,
           name: Blackjack.via_horde({CoreRegistry, server.server_name})
         ) do
      {:ok, pid} ->
        Logger.info("Starting server #{server.server_name}: #{server.user_id}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "#{server.server_name} is already started at #{inspect(pid)}, returning :ignore"
        )

        :ignore
    end
  end

  def get_server(server_name) do
    GenServer.call(Blackjack.via_horde({CoreRegistry, server_name}), {:get_server})
  end

  #   # For updating all connected databases, but will be using single database
  #   # def update_server(%{"server_name" => server_name} = server) do
  #   #   GenServer.call(Blackjack.via_horde({CoreRegistry, server_name}), {:update_server, server})
  #   # end

  # def join_server([server_name, user]) do
  #   GenServer.cast(
  #     Blackjack.via_horde({CoreRegistry, server_name}),
  #     {:join_server, server_name, user}
  #   )
  # end

  # def leave_server([server_name, user]) do
  #   GenServer.cast(
  #     Blackjack.via_horde({CoreRegistry, server_name}),
  #     {:leave_server, server_name, user}
  #   )
  # end

  @impl true
  def init(server) do
    # Process.flag(:trap_exit, true)

    # , {:continue, :load_state} For loading state of saved server
    {:ok, %{server: server, members: []}}
  end

  @impl true
  def handle_call({:get_server}, _from, server) do
    {:reply, server, server}
  end

  #   # For updating all connected databases, but will be using single database
  #   # def handle_call({:update_server, %{"server_name" => server_name}}, _from, _server) do
  #   #   changeset = Server.changeset(%Server{}, %{server_name: server_name})
  #   #   updated_server = Repo.update!(changeset)

  #   #   {:reply, updated_server, updated_server}
  #   # end

  @impl true
  def handle_info({:join_server, [{server_name, user}]}, %{server: server, members: members}) do
    members = Servers.join_server(members, user)
    server = Repo.get(Server, server.id)

    {:ok, changeset} =
      server
      |> Server.changeset(%{
        server_name: server_name,
        user_id: user.id,
        player_count: Enum.count(members)
      })
      |> Repo.update()

    Servers.notify_members(members)
    {:noreply, %{server: changeset, members: members}}
  end

  def handle_info({:leave_server, [{server_name, user}]}, %{server: server, members: members}) do
    members = Servers.leave_server(members, user)
    server = Repo.get(Server, server.id)

    {:ok, changeset} =
      server
      |> Server.changeset(%{
        server_name: server_name,
        user_id: user.id,
        player_count: Enum.count(members)
      })
      |> Repo.update()

    {:noreply, %{server: changeset, members: members}}
  end

  #   @impl true
  #   def handle_info({:update_status}, server) do
  #     nodes =
  #       Blackjack.Core.Supervisor
  #       |> Horde.Cluster.members()
  #       |> Enum.map_every(1, fn {_k, v} -> v end)
  #       |> Enum.reject(fn server -> server == :blackjack_server_0@Developer end)

  #     model = %{screen: :server, data: %{server: server}}

  #     Enum.map(nodes, &send({GuiServer, &1}, {:subscribe_server, model}))

  #     {:noreply, server}
  #   end

  #   # def handle_info({:EXIT, _from, reason}, server) do
  #   #   Logger.warn("Tracking #{server["server_name"]} - Stopped with reason #{inspect(reason)}")
  #   #   {:stop, reason, server}
  #   # end

  #   @impl true
  #   def handle_continue(:load_state, server) do
  #     {:noreply, load_state(server)}
  #   end

  @impl true
  def terminate(_reason, %{server: server, members: members}) do
    # save_state(%{server | "player_count" => player_count(server["server_name"])})
  end
end
