defmodule Blackjack.Core.Servers do
  require Logger

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Blackjack.Accounts
  alias Blackjack.Repo
  alias Blackjack.Core.{Server, Tables, Supervisor}

  def start_link(server_options) do
    GenServer.start_link(__MODULE__, server_options)
  end

  def get_server(server_name) do
    GenServer.call(Blackjack.via_swarm(server_name), {:get_server, server_name})
  end

  def update_server(%{"server_name" => server_name} = server) do
    GenServer.call(Blackjack.via_swarm(server_name), {:update_server, server}, 15000)
  end

  def add_user(server_name, username) do
    GenServer.call(
      Blackjack.via_swarm(server_name),
      {:add_user, server_name, username}
    )
  end

  def remove_user(server_name, username) do
    GenServer.call(
      Blackjack.via_swarm(server_name),
      {:remove_user, server_name, username}
    )
  end

  # @spec create_table(any, any) :: any
  def create_table(server_name, table_name) do
    GenServer.call(
      Blackjack.via_swarm(server_name),
      {:create_table, server_name, table_name}
    )
  end

  @impl true
  # @spec init({:create, any, any} | {:start, any, any}) :: {:ok, any}
  def init({_option, server_name, username} = server_options) do
    server =
      case server_options do
        {:create, ^server_name, ^username} ->
          user_account = Accounts.get_user(username)

          changeset =
            user_account
            |> Ecto.build_assoc(:server)
            |> Server.changeset(%{server_name: server_name})

          case create(changeset) do
            {:ok, server} ->
              server

            {:error, changeset} ->
              Logger.error(inspect(changeset))
              IO.inspect(changeset, label: "ERROR CREATING SERVER")
          end

        {:start, ^server_name, ^username} ->
          start(server_name)
          |> tap(&Logger.info("INIT START SERVER: #{inspect(&1)}"))
      end

    Logger.info("RETURNED SERVER: #{inspect(server)}")
    {:ok, server}
  end

  @impl true
  def handle_call({:swarm, :begin_handoff}, _from, server) do
    Logger.info("BEGIN HANDOFF: #{inspect(node())}")
    {:reply, :restart, server}
  end

  @impl true
  def handle_call({:get_server, _server_name}, _from, server) do
    Logger.info("SERVER: #{inspect(server)}")
    {:reply, server, server}
  end

  @impl true
  def handle_call({:create_table, server_name, table_name}, _from, server) do
    Logger.info("Creating table '#{table_name}' on server '#{server_name}'.")

    # Create table here

    {:reply, "Created table #{table_name} on server #{server_name}.", server}
  end

  @impl true
  def handle_call({:add_user, server_name, username}, _from, server) do
    Swarm.join(server_name, Swarm.whereis_name(username))

    converted_server =
      server
      |> Map.from_struct()
      |> Enum.map(fn {k, v} ->
        k = if is_atom(k) == true, do: k, else: k |> String.to_atom()

        {k, v}
      end)
      |> Map.new()

    changeset =
      Ecto.Changeset.change(
        Kernel.struct!(Server, converted_server),
        player_count: server_name |> Swarm.members() |> Enum.count()
      )

    {:ok, updated_server} = Repo.update(changeset)

    {:reply, "#{username} joined #{server_name}", updated_server}
  end

  def handle_call({:remove_user, server_name, username}, _from, server) do
    Swarm.leave(server_name, Swarm.whereis_name(username))

    changeset =
      Ecto.Changeset.change(server, player_count: Swarm.members(server_name) |> Enum.count())

    {:ok, server} = Repo.update(changeset)

    {:reply, "#{username} joined #{server_name}", server}
  end

  @impl true
  def handle_call({:update_server, %{"server_name" => server_name}}, _from, server) do
    update_player_count = server_name |> Swarm.members() |> Enum.count()

    query =
      from("servers",
        select: [:player_count, :server_name, :table_count, :user_uuid],
        where: [server_name: ^server_name],
        update: [set: [player_count: ^update_player_count]]
      )

    {_, [updated_server]} = Repo.update_all(query, [])

    updated_server =
      for {field, value} <- updated_server, into: %{} do
        {field |> to_string(), value}
      end

    {:reply, updated_server, server}
  end

  @impl true
  def handle_cast({:swarm, :end_handoff, server}, server) do
    Logger.info("END HANDOFF: #{inspect(node())}")
    {:noreply, server}
  end

  @impl true
  def handle_cast({:swarm, :resolve_conflict, _group}, server) do
    {:noreply, server}
  end

  @impl true
  def handle_info({:swarm, :die}, server) do
    {:stop, :shutdown, server}
  end

  # def cache_server_players(server_name) do
  #   Cachex.put(Blackjack.Cache, server_name, server_players())
  # end

  def start_all_servers do
    if Mix.env() != :test do
      Stream.each(
        Repo.all(Server) |> Repo.preload(:user),
        &Supervisor.register({:start, &1.server_name, ""})
      )
      |> Enum.to_list()
    end
  end

  defp create(changeset) do
    case Repo.insert(changeset) do
      {:ok, server} ->
        Logger.info("Created server #{server.server_name}.")
        # Cachex.put!(Blackjack.Cache, server.server_name, server)
        {:ok, server}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp start(server_name) do
    case Repo.get_by!(Server, server_name: server_name) do
      {:error, server} ->
        Logger.info("Failed to start server #{inspect(server.server_name)}.")
        server

      server ->
        Logger.info("Starting server #{inspect(server.server_name)}.")
        # Cachex.put!(Blackjack.Cache, server_name, server)
        server
    end
  end
end
