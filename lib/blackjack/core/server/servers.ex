defmodule Blackjack.Core.Servers do
  use GenServer

  alias Blackjack.{Repo, Cache}
  alias Blackjack.Core.{Server, Tables}

  @registry Registry.Core

  def start_link(server_name) do
    IO.inspect(server_name, label: "SERVER NAME")

    GenServer.start_link(__MODULE__, server_name,
      name: Blackjack.via_tuple(@registry, server_name)
    )
  end

  @impl true
  def init(server_name) do
    changeset = Server.changeset(%Server{}, %{server_name: server_name})
    IO.inspect(changeset, label: "CHANGESET")

    server =
      case Repo.insert(changeset) do
        {:ok, server} ->
          IO.puts("#{server.server_name} created.")

        {:error, changeset} ->
          changeset
      end

    {:ok, {self(), server}}
  end

  def create_table(server_name, table_name) do
    IO.puts("Creating table '#{table_name}' on server '#{server_name}'.")

    child_spec = {Tables, table_name}

    Cache.put(table_name, [])

    Blackjack.lookup(@registry, server_name)
    |> GenServer.start_child(child_spec)
  end

  def remove_table(server_name, table_name) do
    [{table_id, _}] = Registry.lookup(@registry, table_name)

    Blackjack.lookup(@registry, server_name)
    |> GenServer.terminate_child(table_id)
  end

  def list_tables_by_pid(server_name) do
    Task.async_stream(
      children(server_name),
      fn {_, pid, _, _} ->
        pid
      end,
      ordered: true
    )
    |> Enum.to_list()
    |> Keyword.get_values(:ok)
  end

  def list_tables_by_name(server_name) do
    Enum.map(list_tables_by_pid(server_name), fn pid ->
      Registry.keys(@registry, pid) |> Enum.at(0) |> IO.puts()
    end)
  end

  def children(server_name) do
    Blackjack.lookup(@registry, server_name)
    |> GenServer.which_children()
  end

  def count_children(server_name) do
    Blackjack.lookup(@registry, server_name)
    |> GenServer.count_children()
  end
end
