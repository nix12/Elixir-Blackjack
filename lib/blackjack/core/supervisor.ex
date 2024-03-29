defmodule Blackjack.Core.Supervisor do
  @moduledoc false
  require Logger

  use Horde.DynamicSupervisor

  alias Blackjack.Core.ServerManager

  # Client

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(__MODULE__, [strategy: :one_for_one, shutdown: 1000],
      name: __MODULE__
    )
  end

  # Server options is in the shap of: {action, user, server}
  def start_server(server) do
    child_spec = %{
      id: ServerManager,
      start: {ServerManager, :start_link, [server]},
      type: :worker,
      restart: :transient
    }

    Horde.DynamicSupervisor.start_child(
      __MODULE__,
      child_spec
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

  defp members() do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end
