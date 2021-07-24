defmodule Blackjack.Core.Servers do
  require Logger

  use GenServer

  alias Blackjack.{Repo, Cache}
  alias Blackjack.Core.{Server, Tables}

  @registry Registry.Core

  def start_link({_option, server_name} = server_options) do
    GenServer.start_link(__MODULE__, server_options,
      name: Blackjack.via_tuple(@registry, server_name)
    )
  end

  def create_table(server_name, table_name) do
    GenServer.call(
      Blackjack.lookup(@registry, server_name),
      {:create_table, server_name, table_name}
    )
  end

  @impl true
  def init({_option, server_name} = server_options) do
    changeset = Server.changeset(%Server{}, %{server_name: server_name})

    server =
      case server_options do
        {:create, server_name} ->
          create(changeset)

        {:start, server_name} ->
          start(server_name)
      end

    {:ok, server}
  end

  @impl true
  def handle_call({:create_table, server_name, table_name}, _from, server) do
    Logger.info("Creating table '#{table_name}' on server '#{server_name}'.")

    # Create table here

    {:reply, "Created table #{table_name} on server #{server_name}.", server}
  end

  def server_players do
    []
  end

  def cache_server_players(server_name) do
    Cachex.put(Blackjack.Cache, server_name, server_players())
  end

  def start_all do
    for server <- Repo.all(Server) do
      start_link({:start, server.server_name})
    end
  end

  defp create(changeset) do
    case Repo.insert(changeset) do
      {:ok, server} ->
        Logger.info("Created server #{server.server_name}.")
        server

      {:error, changeset} ->
        changeset
    end
  end

  defp start(server_name) do
    case Repo.get_by!(Server, server_name: server_name) do
      {:error, server} ->
        Logger.info("Failed to start server #{inspect(server.server_name)}.")
        server

      server ->
        Logger.info("Starting server #{inspect(server.server_name)}.")
        server
    end
  end
end
