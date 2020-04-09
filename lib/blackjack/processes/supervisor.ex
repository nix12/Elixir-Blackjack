defmodule Blackjack.Processes.Supervisor do
  use Supervisor

  def start_link(opts) do
    IO.puts("Supervisor started.")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Blackjack.Processes.Server, name: Blackjack.Processes.Server}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
