defmodule Blackjack.Notifier.CoreNotifier do
  # Handles server_name instructionis
  use GenServer

  alias Blackjack.Core.CoreRegistry

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Blackjack.via_horde({CoreRegistry, __MODULE__}))
  end

  def publish(server_name, server_instruction) do
    GenServer.cast(
      Blackjack.via_horde({CoreRegistry, __MODULE__}),
      {:notify_server, server_name, server_instruction}
    )
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:notify_server, server_name, server_instruction}, server) do
    # {:join_server, [server_name, user]}
    {action, args} = decode_instruction(server_instruction)

    events = [args | []]

    [{server_pid, _}] = Horde.Registry.lookup(CoreRegistry, server_name)
    send(server_pid, {action, events})

    {:noreply, server}
  end

  defp decode_instruction({:join_server, server_name, user}),
    do: {:join_server, {server_name, user}}

  defp decode_instruction({:leave_server, server_name, user}),
    do: {:leave_server, {server_name, user}}
end
