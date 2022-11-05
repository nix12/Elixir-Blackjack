defmodule Blackjack.Accounts.Supervisor do
  @moduledoc false
  require Logger

  use Horde.DynamicSupervisor

  alias Blackjack.Accounts.UserManager

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(__MODULE__, [strategy: :one_for_one], name: __MODULE__)
  end

  def start_user(user) do
    child_spec = %{
      id: UserManager,
      start: {UserManager, :start_link, [user]},
      type: :worker,
      restart: :transient
    }

    Horde.DynamicSupervisor.start_child(
      __MODULE__,
      child_spec
    )
  end

  @impl true
  def init(init_arg) do
    Logger.info("Starting Accounts Supervisor.")

    [strategy: :one_for_one, members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  defp members() do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end
