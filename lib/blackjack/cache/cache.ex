# Cache for Blackjack games.
defmodule Blackjack.Cache do
  use GenServer

  @registry Registry.Core
  @table :blackjack_cache

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, __MODULE__))
  end

  # Server

  def init(:ok) do
    IO.puts("Initializing cache.")

    :ets.new(@table, [:set, :public, :named_table])

    {:ok, %{}}
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> value |> Enum.reverse()
      _ -> nil
    end
  end

  def put(key, value) do
    true = :ets.insert(@table, {key, value})
    :ok
  end

  def update(key, value) do
    :ets.update_element(@table, key, {2, value})
  end
end
