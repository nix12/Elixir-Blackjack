defmodule Blackjack.Processes.Server do
  use GenServer

  # client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def find(table) do
    GenServer.call(__MODULE__, {:find_game, table})
  end

  def list do
    GenServer.call(__MODULE__, {:list})
  end

  def new_server(server, table) do
    IO.puts("Creating new server.")

    GenServer.cast(__MODULE__, {:new_server, server, table})
  end

  def new_table(server, table) do
    IO.puts("Create new table")

    GenServer.cast(__MODULE__, {:new_table, server, table})
  end

  def join_table(table, player) do
    GenServer.call(__MODULE__, {:join_table, table, player})
  end

  # server
  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:find_game, table}, _from, state) do
    match =
      Enum.map(state, fn server ->
        {_, tables} = server
        Map.fetch!(tables, table)
      end)

    {:reply, match, state}
  end

  @impl true
  def handle_call({:list}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:join_table, table, player}, _from, state) do
    [{_, players}] =
      _updated_state =
      Enum.map(state, fn {_server, tables} ->
        Map.get_and_update(tables, table, fn value ->
          {value, [player]}
        end)
      end)

    {:reply, players, state}
  end

  @impl true
  def handle_cast({:new_server, server, table}, state) do
    if Map.has_key?(state, server) do
      {:noreply, state}
    else
      {:noreply, Map.put(state, server, table)}
    end
  end

  @impl true
  def handle_cast({:new_table, server, table}, state) do
    {_, players} =
      _updated_state =
      Map.get_and_update(state, server, fn value ->
        {value, %{table => []}}
      end)

    {:noreply, players}
  end
end
