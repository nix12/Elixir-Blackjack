defmodule Blackjack.Accounts.AccountsRegistry do
  @moduledoc false
  use Horde.Registry

  def start_link(_) do
    Horde.Registry.start_link(__MODULE__, [keys: :unique], name: __MODULE__)
  end

  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  def count(server) do
    server |> String.to_atom() |> Horde.Cluster.members() |> Enum.count()
  end

  defp members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {__MODULE__, node} end)
  end
end
