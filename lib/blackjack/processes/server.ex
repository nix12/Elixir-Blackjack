defmodule Blackjack.Processes.Server do
  use GenServer

  # client
  def start_link(opts) do
    IO.puts("Server Started")
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def find(name) do
    GenServer.call(__MODULE__, {:find_game, name})
  end

  def list do
    GenServer.call(__MODULE__, {:list})
  end

  def start do
    IO.puts("Creating new game.")
    name = IO.gets("What would you like to call this game?\n")
    GenServer.cast(__MODULE__, {:start, name})
  end

  # server
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:find, name}, _from, games) do
    if Enum.find(games, & &1)[name] do
      {:reply, games, games}
    else
      {:reply, "Game not found.", games}
    end
  end

  @impl true
  def handle_call({:list}, _from, games) do
    {:reply, games, games}
  end

  @impl true
  def handle_cast({:start, name}, games) do
    {:ok, game} = Blackjack.start_game([])
    {:noreply, [%{name => game} | games]}
  end
end
