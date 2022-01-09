defmodule Blackjack.Core.Supervisor do
  require Logger

  use Horde.DynamicSupervisor

  alias Blackjack.Core.Servers

  # Client

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(__MODULE__, [strategy: :one_for_one, shutdown: 1000],
      name: __MODULE__
    )
  end

  # Server

  @impl true
  def init(init_arg) do
    Logger.info("Starting Core Supervisor.")

    [strategy: :one_for_one, members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  def start_child(server_options) do
    child_spec = %{
      id: Servers,
      start: {Servers, :start_link, [server_options]},
      type: :worker,
      restart: :transient
    }

    Horde.DynamicSupervisor.start_child(
      __MODULE__,
      child_spec
    )
  end

  defp members() do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end
