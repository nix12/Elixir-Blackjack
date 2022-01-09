defmodule Blackjack.Accounts.Supervisor do
  require Logger

  use Horde.DynamicSupervisor

  alias Blackjack.Accounts.Users

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(__MODULE__, [strategy: :one_for_one], name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    Logger.info("Starting Accounts Supervisor.")

    [strategy: :one_for_one, members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  def start_child(user) do
    child_spec = %{
      id: Users,
      start: {Users, :start_link, [user]},
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
