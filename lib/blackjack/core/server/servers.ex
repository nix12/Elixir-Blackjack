defmodule Blackjack.Core.Servers do
  require Logger

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Blackjack.{Repo, Accounts}
  alias Blackjack.Core.{CoreRegistry, Server, Supervisor, StateManager}

  def start_link({_options, server_name, _username} = server_options) do
    case GenServer.start_link(__MODULE__, server_options,
           name: Blackjack.via_horde({CoreRegistry, server_name})
         ) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("#{server_name} is already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  def get_server(server_name) do
    GenServer.call(Blackjack.via_horde({CoreRegistry, server_name}), {:get_server})
  end

  def update_server(%{"server_name" => server_name} = server) do
    GenServer.call(Blackjack.via_horde({CoreRegistry, server_name}), {:update_server, server})
  end

  def add_user(server_name, username) do
    GenServer.call(
      Blackjack.via_horde({CoreRegistry, server_name}),
      {:add_user, server_name, username}
    )
  end

  def remove_user(server_name, username) do
    GenServer.call(
      Blackjack.via_horde({CoreRegistry, server_name}),
      {:remove_user, server_name, username}
    )
  end

  @impl true
  def init(server_options) do
    Process.flag(:trap_exit, true)

    PubSub
    |> Process.whereis()
    |> Process.link()

    server =
      case server_options do
        {:create, server_name, username} ->
          case create(Accounts.get_user(username), server_name) do
            {:ok, server} ->
              server

            {:error, new_server} ->
              IO.inspect(new_server, label: "ERROR CREATING SERVER")
          end

        {:start, server_name, _username} ->
          start(server_name)
      end

    {:ok, server, {:continue, :load_state}}
  end

  @impl true
  def handle_call({:get_server}, _from, server) do
    {:reply, server, server}
  end

  def handle_call({:update_server, %{"server_name" => server_name}}, _from, _server) do
    {_, [updated_server]} = Repo.update_all(update_by_server_name(server_name), [])
    {:reply, updated_server, updated_server}
  end

  def handle_call({:add_user, server_name, username}, _from, _server) do
    join_server(server_name, username)

    {_, [updated_server]} = Repo.update_all(update_by_server_name(server_name), [])

    updated_server =
      for {field, value} <- updated_server, into: %{} do
        {field |> to_string(), value}
      end

    {:reply, updated_server, updated_server}
  end

  def handle_call({:remove_user, server_name, username}, _from, _server) do
    leave_server(server_name, username)

    {_, [updated_server]} = Repo.update_all(update_by_server_name(server_name), [])

    updated_server =
      for {field, value} <- updated_server, into: %{} do
        {field |> to_string(), value}
      end

    {:reply, updated_server, updated_server}
  end

  @impl true
  def handle_continue(:load_state, server) do
    {:noreply, load_state(server)}
  end

  @impl true
  def terminate(_reason, server) do
    Enum.each(PubSub.subscribers(server.server_name), fn user ->
      PubSub.unsubscribe(user, server.server_name)
    end)

    save_state(%{server | player_count: player_count(server.server_name)})
  end

  def start_all_servers do
    if Mix.env() != :test do
      query =
        from(s in "servers",
          select: [
            :player_count,
            :server_name,
            :table_count,
            :user_uuid,
            :inserted_at,
            :updated_at
          ]
        )

      Stream.each(
        Repo.all(query),
        &Supervisor.start_child({:start, &1.server_name, ""})
      )
      |> Enum.to_list()
    end
  end

  defp create(%{uuid: uuid}, server_name) do
    {_, [new_server]} =
      Server.insert(%Server{
        server_name: server_name |> to_string(),
        user_uuid: uuid,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      })

    {:ok, new_server}
  end

  defp start(server_name) do
    case server_name |> query_servers |> Repo.all() do
      [] ->
        Logger.info("Failed to start server #{inspect(server_name)}.")

      [server] ->
        Logger.info("Starting server #{inspect(server.server_name)}.")
        # Cachex.put!(Blackjack.Cache, server_name, server)
        server
    end
  end

  defp query_servers(server_name) do
    from(s in "servers",
      select: [:player_count, :server_name, :table_count, :user_uuid, :inserted_at, :updated_at],
      where: [server_name: ^server_name]
    )
  end

  def update_by_server_name(server_name) do
    from(s in "servers",
      select: [:player_count, :server_name, :table_count, :user_uuid, :inserted_at, :updated_at],
      where: [server_name: ^server_name],
      update: [set: [player_count: ^player_count(server_name)]]
    )
  end

  def save_state(server) do
    StateManager.insert(%{
      server_name: server["server_name"],
      data: Jason.encode!(server),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    })
  end

  def load_state(server) do
    query =
      from(s in "states",
        where: [server_name: ^server.server_name],
        select: [:server_name, :data]
      )

    case Repo.all(query) do
      [] ->
        Logger.info("Failed to retrieve server data for #{inspect(server.server_name)}.")
        server.server_name |> start()

      [%{server_name: server_name, data: data}] ->
        Logger.info("Retreiving server data for #{inspect(server_name)}.")

        # Cachex.put!(Blackjack.Cache, server_name, server)
        Jason.decode!(data)
    end
  end

  defp player_count(server_name) do
    server_name
    |> PubSub.subscribers()
    |> Enum.count()
  end

  defp join_server(server_name, username) do
    [{pid, _}] =
      {Blackjack.Accounts.AccountsRegistry, username}
      |> Blackjack.via_horde()
      |> Horde.Registry.whereis()

    PubSub.subscribe(pid, server_name)
  end

  defp leave_server(server_name, username) do
    [{pid, _}] =
      {Blackjack.Accounts.AccountsRegistry, username}
      |> Blackjack.via_horde()
      |> Horde.Registry.whereis()

    PubSub.unsubscribe(pid, server_name)
  end
end
